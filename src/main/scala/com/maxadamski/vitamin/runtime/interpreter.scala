package com.maxadamski.vitamin.runtime

import System.err.{println => eprintln}
import System.exit
import java.nio.charset.StandardCharsets.UTF_8

import collection.mutable.{Map => MutableMap}
import PartialFunction._

import com.maxadamski.vitamin.parser._
import com.maxadamski.vitamin.ast.{Atom, PrattDecoder, Term, Tree}
import com.maxadamski.vitamin.ast.Term._
import com.maxadamski.vitamin.debug.Error._
import com.maxadamski.vitamin.runtime.TypeSystem._
import TypeSystem._
import Core.{require, panic}

object TypeSystem {
  case class Poly(typ: Type, ctx: List[Spec] = Nil) {
    override def toString: String = {
      typ.toString + (if (ctx.nonEmpty) ctx.mkString(" where (", " ", ")") else "")
    }
  }

  sealed trait Type {
    override def toString: String = this match {
      case TypeName(x) => x
      case TypeCons(TypeName("->"), List(x, y)) => f"($x -> $y)"
      case TypeCons(TypeName(","), args) => args.mkString("(", ", ", ")")
      case TypeCons(head, tail) => tail.mkString(f"$head(", " ", ")")
    }
  }

  case class TypeName(x: String) extends Type
  case class TypeCons(x: Type, y: List[Type]) extends Type

  sealed trait Spec
  case class sat(x: TypeCons) extends Spec
  case class forall(x: TypeName) extends Spec
  //case class pred(x: String, y: Type) extends Spec

  def kindOf(env: Env, ctx: List[Spec])(typ: Type): Int = typ match {
    case TypeCons(head, tail) =>
      kindOf(env, ctx)(head) - tail.length
    case it@TypeName(name) =>
      if (ctx contains forall(it)) return 1
      val local = env.findKindOf(name)
      require(typ, local.nonEmpty, "undefined type")
      local.get.kindOf(name)
  }

  def validateType(env: Env)(ctx: List[Spec], typ: Type): Unit = {
    val (arity, given) = typ match {
      case TypeCons(head, tail) =>
        tail.foreach(validateType(env)(ctx, _))
        head match {
          case TypeName(",") => (tail.length, tail.length) // tuples have arbitrary kind >= 3
          case _ => (kindOf(env, ctx)(head) - 1, tail.length)
        }
      case it@TypeName(_) =>
        (kindOf(env, ctx)(it) - 1, 0)
    }
    require(typ, arity == given, f"type constructor takes $arity arguments, but was given $given")
  }

  def validatePoly(env: Env)(poly: Poly): Unit = validateType(env)(poly.ctx, poly.typ)

  def unifies(typeA: Type, typeB: Type): Boolean = (typeA, typeB) match {
    case (TypeName(x), TypeName(y)) => x == y
    case (TypeCons(x, u), TypeCons(y, v)) => unifies(x, y) && (u zip v).forall { case (a, b) => unifies(a, b) }
    case _ => false
  }

  def unifies(x: TypeSystem.Poly, y: TypeSystem.Poly): Boolean = unifies(x.typ, y.typ)

  def validatedApply(f: Poly, args: List[Poly]): Poly = (f, args) match {
    case (t, Nil) =>
      t
    case (Poly(TypeCons(TypeName("->"), List(x, y)), ctx), head :: tail) =>
      require(None, unifies(Poly(x, ctx), head), s"argument type mismatch - expected: $x, got $head")
      validatedApply(Poly(y, ctx), tail)
  }
}

object Core {
  type BuiltinLambda = List[Any] => Any

  val QUASIQUOTE = Atom("quasiquote")
  val UNQUOTE = Atom("unquote")
  val UNQUOTE_SPLICING = Atom("unquote")
  val CONS = Atom("cons")
  val TERM = Atom("Term")
  val APPEND = Atom("append")
  
  implicit class EitherExtension[Left, Right](value: Either[Left, Right]) {
    def map[T](transform: Right => T): Either[Left, T] = value match {
      case Left(inner) => Left(inner)
      case Right(inner) => Right(transform(inner))
    }

    def toOption(): Option[Right] = value match {
      case Left(_) => None
      case Right(inner) => Some(inner)
    }
  }

  case class SyntaxError(message: String) extends Exception
  case class RuntimeError(message: String) extends Exception

  def reportPrattError(env: Env)(error: PrattError): Unit = {
    val (reason, curr, last) = (error.reason, error.curr, error.last)
    val message = reason match {
      case Reason.UnexpectedEOF =>
        error__parser__unexpected_eof(env)
      case Reason.UnexpectedNull =>
        error__parser__null_unexpected_token(env, curr)
      case Reason.UnexpectedLeft =>
        error__parser__null_unexpected_token(env, curr)
      case Reason.UnknownLeft =>
        error__parser__left_not_registered(env, curr)
      case Reason.UnknownNull =>
        error__parser__null_not_registered(env, curr)
      case Reason.BadPrecedenceLeft =>
        error__parser__left_bad_precedence(env, curr, last)
      case Reason.BadPrecedenceNull =>
        error__parser__null_bad_precedence(env, curr, last)
    }
    throw new Exception(message)
  }

  def require(term: Any, pred: Boolean, message: String): Unit = {
    if (!pred) panic(term, message)
  }

  def panic(term: Any, message: String): Nothing = {
    throw new Exception(f"$term: $message")
  }

  def toType(ast: Tree): Type = ast match {
    case Atom(x) => TypeName(x)
    case Term(head :: tail) => TypeCons(toType(head), tail.map(toType))
    case Term(Nil) => TypeName("Unit")
  }

  def toPoly(ast: Tree): Poly = Poly(toType(ast))

  def toTerm(x: Any): Tree = x match {
    case x: Tree => x
    case x: List[_] => Term(x.map(toTerm))
    case _ => throw new Exception(f"cannot cast $x to term!")
  }

  object DynamicIL {
    sealed trait Form
    case class Val(x: Any) extends Form
    case class Get(x: String) extends Form
    case class Set(x: String, y: Form) extends Form
    case class Let(x: String, y: Form, mutable: Boolean = false) extends Form
    case class App(x: Form, y: List[Form]) extends Form
    case class Fun(head: List[String], body: Form) extends Form
    case class Seq(x: List[Form]) extends Form
  }

  // -- SPECIAL FORMS ----------------------------------------------------------

  def parse_once(env: Env)(tree: Tree): (Tree, Boolean) = tree match {
    case it@Term(PARSE :: _) =>
      val newEnv = env.extend()
      newEnv.node = it
      // if the parser was successful, decode the result
      val result = newEnv.parser.parse(it).map(PrattDecoder.decode(_))
      // otherwise report the error
      result.left.map(reportPrattError(newEnv))
      (result.toOption.getOrElse(Term(Nil)), true)
    case _ =>
      (tree, false)
  }

  def qq_parse(env: Env)(tree: Tree): Tree = parse_once(env)(tree)._1

  def quasiquote(env: Env)(ast: Tree, list: Boolean = false): Tree = qq_parse(env)(ast) match {
    // Adapted from Appendix A in Quasiquotation in Lisp, by Badwen
    case Term(List(UNQUOTE, x)) =>
      val y = qq_parse(env)(x)
      if (list) Term(TUPLE :: y :: Nil) else y
    case Term(List(UNQUOTE_SPLICING, x)) =>
      require(ast, list, "cannot unquote-splicing here!")
      qq_parse(env)(x)
    case Term(List(QUASIQUOTE, x)) =>
      quasiquote(env)(quasiquote(env)(x), list = list)
    case Term(head :: tail) =>
      val one = quasiquote(env)(head, list = true)
      val two = quasiquote(env)(Term(tail))
      val it = Term(APPEND :: one :: two :: Nil)
      if (list) Term(TUPLE :: it :: Nil) else it
    case Term(Nil) =>
      Term(TUPLE :: Nil)
    case Atom(_) =>
      val it = Term(QUOTE :: ast :: Nil)
      if (list) Term(TUPLE :: it :: Nil) else it
  }

  // -- EXPAND -----------------------------------------------------------------

  def expand(env: Env, toplevel: Boolean = false)(tree: Tree): Tree = tree match {
    case it@Term(PARSE :: args) =>
      // term parsing was deferred to the Pratt parser
      val parsed = parse_once(env)(it)._1
      expand(env)(parsed)

    case Term(BLOCK :: args) =>
      val expanded = args.map(expand(env))
      val nonEmpty = expanded.flatMap { case Term(Nil) => None case other => Some(other) }
      Term(BLOCK :: nonEmpty)

    case Term(UNQUOTE :: _) =>
      panic(tree, "cannot unquote outside of a quasiquote")

    case Term(UNQUOTE_SPLICING :: _) =>
      panic(tree, "cannot unquote_splicing outside of a quasiquote")

    case Term(QUASIQUOTE :: args) => // macro
      require(tree, args.length == 1, s"wrong number of arguments - expected 1, got ${args.length}")
      quasiquote(env)(args(0))

    case Term(Atom("#operator_group") :: args) =>
      require(tree, args.length == 4, s"wrong number of arguments - expected 4, got ${args.length}")
      require(tree, args.forall(_.isInstanceOf[Atom]), f"wrong argument types - expected (Atom, Atom, Atom, Atom)")
      val Atom(name) :: Atom(kind) :: Atom(maybeGt) :: Atom(maybeLt) :: Nil = args

      val (fixity, associativity) = OpUtils.opKind(kind)
      val gt = if (maybeGt != "nil") Some(maybeGt) else None
      val lt = if (maybeLt != "nil") Some(maybeGt) else None
      val group = OpGroup(name, fixity, associativity, gt, lt)
      env.parser.addGroup(group)
      Term(Nil)

    case Term(Atom("#operator") :: args) =>
      require(tree, args.length == 2, f"wrong number of arguments - expected 2, got ${args.length}")
      require(tree, args.forall(_.isInstanceOf[Atom]), "wrong argument types - expected (Atom, Atom)")
      val Atom(group) :: Atom(name) :: Nil = args

      val opName = OpName(group, name)
      env.parser.addName(opName)
      env.parser.updateParser()
      Term(Nil)

    case Term(DEF :: rawArgs) => // desugar macro definition
      val args = rawArgs.map(expand(env))
      val (name, head, body) = args match {
        case Term(Atom(_1) :: _2) :: _3 :: Nil => (_1, _2, _3)
        case Term(Atom(_1) :: _2) :: Nil => (_1, _2, Term(Nil)) // forward declaration
        case _ => panic(tree, f"wrong number of arguments - expected 2, got ${args.length}")
      }
      val formals = head map {
        case Atom(x) => x
        case _ => panic(tree, f"invalid macro formals $head, expected Tuple(Term)")
      }
      env.macros += name -> Macro(formals, body, env)
      Term(Nil)

    case Term(Atom("lambda") :: args) =>
      require(tree, args.length == 2, "wrong number of arguments - expected lambda(head, body)")
      val atoms = args(0) match {
        case it@Atom(_) => it :: Nil
        case it@Term(TUPLE :: x) => x
        case _ => panic(tree, "bad lambda parameters expected Atom or Tuple(Atom)")
      }
      val param = atoms map {
        case it@Atom(_) => it
        case _ => panic(tree, "bad lambda parameters expected Atom or Tuple(Atom)")
      }
      Term(Atom("lambda") :: Term(param) :: expand(env)(args(1)) :: Nil)

    case Term(Atom("typfun") :: args) =>
      require(tree, args.length >= 2, "wrong number of arguments - expected >= 2")
      Term(Atom("->") :: args.map(expand(env)))

    case Term(Atom("typtup") :: args) =>
      require(tree, args.length >= 2, "wrong number of arguments - expected >= 2")
      Term(Atom(",") :: args.map(expand(env)))

    case Term(Atom("defvar") :: args) =>
      require(tree, args.length == 3, "wrong number of arguments - expected defvar(name, type, expr)")
      Term(Atom("defvar") :: args.map(expand(env)))

    case Term(Atom(name) :: _) if env.findMacro(name).nonEmpty =>
      val parsed = parse_once(env)(tree)._1
      val Term(_ :: tail) = parse_once(env)(tree)._1
      val args = tail.map(expand(env))
      val Macro(params, body, local) = env.findMacro(name).get.macros(name)
      require(args, params.length == args.length, "wrong number of arguments")
      (params zip args) foreach { x => local.variables += x }
      val expr = expand(local)(body)
      val (exprForm, exprType) = transform(local)(expr)
      var res1 = eval(local)(exprForm)
      val res2 = toTerm(res1)
      val res3 = expand(local)(res2)
      res3

    case _ =>
      tree
  }

  def transformNumber(env: Env, hint: Option[Poly] = None)(
    sign: String, integer: String, fraction: String
  ): (DynamicIL.Form, Poly) = {
      // todo: check if number looses precision
      val T = List("I8", "I16", "I32", "I64", "F32", "F64")
      val float = fraction.nonEmpty
      val str = if (float) f"$integer.$fraction" else integer
      val sgn = sign match {
        case "+" => +1
        case "-" => -1
        case _ => panic(None, f"invalid number sign $sign")
      }
      val t = hint match {
        case Some(Poly(TypeName(x), _)) if T contains x => x
        case _ => if (float) "F64" else "I64"
      }
      val x: Any = t match {
        case "I8"  => sgn * str.toByte
        case "I16" => sgn * str.toShort
        case "I32" => sgn * str.toInt
        case "I64" => sgn * str.toLong
        case "F32" => sgn * str.toFloat
        case "F64" => sgn * str.toDouble
      }
      DynamicIL.Val(x) -> Poly(TypeName(t))
  }

  def transform(env: Env, hint: Option[Poly] = None)(ast: Tree): (DynamicIL.Form, Poly) = ast match {
    case Atom(name) =>
      val local = env.findTypeOf(name)
      require(ast, local.nonEmpty, f"reference to undefined variable $name")
      val varType = local.get.typeOf(name)
      DynamicIL.Get(name) -> varType

    case Term(Atom("defvar") :: Atom(name) :: rawType :: varExpr :: Nil) =>
      // check if variable is not defined
      require(ast, !(env.typeOf contains name), f"attempting to redefine the variable $name")
      val varType = toPoly(rawType)
      validatePoly(env)(varType)
      val (exprForm, exprType) = transform(env, Some(varType))(varExpr)
      validatePoly(env)(exprType)
      require(varExpr, unifies(varType, exprType), f"type mismatch - expected: $varType, got: $exprType")
      // check if varType and exprType unify
      env.typeOf(name) = exprType
      val mutable = true
      DynamicIL.Let(name, exprForm, mutable) -> exprType

    case Term(Atom("setvar") :: Atom(name) :: varExpr :: Nil) =>
      // check if variable varName is defined
      val local = env.findTypeOf(name)
      require(ast, local.nonEmpty, f"assignment to undefined variable $name")
      val varType = local.get.typeOf(name)
      // check if variable varType and exprType unifies
      val (exprForm, exprType) = transform(env, Some(varType))(varExpr)
      require(varExpr, unifies(varType, exprType), f"type mismatch - expected: $varType, got: $exprType")
      DynamicIL.Set(name, exprForm) -> exprType

    case Term(NUMBER :: Atom(sign) :: Atom(integer) :: Atom(fraction) :: Nil) =>
      transformNumber(env, hint)(sign, integer, fraction)

    case Term(STRING :: Atom(string) :: Nil) =>
      val bytes = string.getBytes(UTF_8)
      val t = Poly(TypeCons(TypeName("Array"), TypeName("I8") :: Nil))
      DynamicIL.Val(bytes) -> t

    case Term(LAMBDA :: Term(rawFormals) :: bodyExpr :: Nil) =>
      val formals = rawFormals.map(_.asInstanceOf[Atom].value)
      val (bodyForm, bodyType) = transform(env)(bodyExpr)
      DynamicIL.Fun(formals, bodyForm) -> bodyType

    case Term(BLOCK :: args) =>
      val local = env.extend()
      val exprs = args.map(transform(local))
      val forms = exprs.map(_._1)
      val lastType = exprs.last._2
      DynamicIL.Seq(forms) -> lastType

    //case Term(QUOTE :: term :: Nil) =>

    case Term(head :: tail) =>
      val ((headForm, headType), args) = (transform(env)(head), tail.map(transform(env)))
      val (argForms, argTypes) = (args.map(_._1), args.map(_._2))
      // todo: check if headType args unify with argTypes
      DynamicIL.App(headForm, argForms) -> validatedApply(headType, argTypes)

    case Term(Nil) =>
      DynamicIL.Seq(Nil) -> Poly(TypeName("Unit"))
  }

  // -- EVALUATE ---------------------------------------------------------------

  def eval(env: Env)(form: DynamicIL.Form): Any = form match {
    case DynamicIL.Val(x) => x
    case DynamicIL.Get(x) => env.findVariable(x).get.variables(x)
    case DynamicIL.Set(x, y) => env.findVariable(x).get.variables(x) = eval(env)(y)
    case DynamicIL.Let(x, y, _) => env.variables(x) = eval(env)(y)
    case DynamicIL.Fun(x, y) => Lambda(x, y, env)
    case DynamicIL.App(x, y) =>
      val args = y.map(eval(env))
      val res = eval(env)(x) match {
        case Lambda(params, body, local) =>
          params.zip(args).foreach(local.variables += _)
          eval(local)(body)
        case x =>
          x.asInstanceOf[BuiltinLambda](args)
      }
      res
    case DynamicIL.Seq(x) =>
      val local = env.extend()
      val res = x.map(eval(local))
      if (res.nonEmpty) res.last else ()
  }
}

