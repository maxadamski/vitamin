package com.maxadamski.vitamin.runtime

import System.err.{println => eprintln}
import System.exit
import java.nio.charset.StandardCharsets.UTF_8

import collection.mutable.{Map => MutableMap}
import PartialFunction._
import com.maxadamski.vitamin.parser2.{BadMix, BadPrecedenceLeft, BadPrecedenceNull, OpGroup, OpName, OpUtils, PrattError, PrattParser, Reason, UnexpectedEOF, UnknownLeft, UnknownNull, Error => ParserError}
import com.maxadamski.vitamin.ast.{Atom, Term, Tree}
import com.maxadamski.vitamin.ast.Term._
import com.maxadamski.vitamin.debug.Error._
import com.maxadamski.vitamin.runtime.TypeSystem._
import TypeSystem._
import Core.{panic, require}
import com.maxadamski.vitamin.ScalaBuiltins
import com.maxadamski.vitamin.debug.Report

object Core {
  type BuiltinLambda = List[Any] => Any

  val QUASIQUOTE = Atom("quasiquote")
  val UNQUOTE = Atom("unquote")
  val UNQUOTE_SPLICING = Atom("unquote")
  val CONS = Atom("cons")
  val TERM = Atom("Term")
  val APPEND = Atom("append")

  case class SyntaxError(message: String) extends Exception
  case class RuntimeError(message: String) extends Exception

  def reportPrattError(env: Env)(error: ParserError): String = error match {
    case UnexpectedEOF(last) =>
      error__parser__unexpected_eof(env)
    case BadPrecedenceLeft(curr, last) =>
      error__parser__left_bad_precedence(env, curr, last)
    case BadPrecedenceNull(curr, last) =>
      error__parser__null_bad_precedence(env, curr, last)
    case UnknownLeft(curr, last) =>
      error__parser__left_not_registered(env, curr)
    case UnknownNull(curr, last) =>
      error__parser__null_not_registered(env, curr)
    case BadMix(name, expected, actual) =>
      env.node = actual
      error__parser__bad_mix(env, name, expected, actual)
    case PrattError(reason, curr, last) =>
      reason match {
        case Reason.UnexpectedNull =>
          error__parser__null_unexpected_token(env, curr)
        case Reason.UnexpectedLeft =>
          error__parser__null_unexpected_token(env, curr)
      }
  }

  def require(env: Env, term: Any, pred: Boolean, message: String): Unit = {
    if (!pred) panic(env, term, message)
  }

  def panic(env: Env, term: Any, message: String): Nothing = {
    val m = term match {
      case x: Tree =>
        Report.compileError2(env, x, name = "fatal error", body = message)
      case _ =>
        f"$term - $message"
    }
    eprintln(m)
    throw new Exception()
  }

  def toType(ast: Tree): Type = ast match {
    case Atom(x) => TypeName(x)
    case Term(head :: tail) => TypeCons(toType(head), tail.map(toType))
    case Term(Nil) => TypeName("Unit")
  }

  def toPoly(ast: Tree): Poly = Poly(toType(ast))

  def toTerm(x: Any): Tree = x match {
    case x: Tree => x
    case x: Array[_] =>
      val t = Term(x.map(toTerm).toList)
      t.span = t.compSpan
      t
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
    case class Loop(x: Form, y: Form) extends Form
    case class Cond(x: Form, y: Form, z: Form) extends Form
  }

  // -- SPECIAL FORMS ----------------------------------------------------------

  def parse_once(env: Env)(tree: Tree): (Tree, Boolean) = tree match {
    case it@Term(PARSE :: _) =>
      val newEnv = env.extend()
      newEnv.node = it
      // if the parser was successful, decode the result
      val result = newEnv.parser.parse(it)
      result.mapErr { e =>
        eprintln(reportPrattError(env)(e))
        throw new Exception(e.toString)
      }
      (result.get, true)
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
      require(env, ast, list, "cannot unquote-splicing here!")
      qq_parse(env)(x)
    case Term(List(QUASIQUOTE, x)) =>
      quasiquote(env)(quasiquote(env)(x), list = list)
    case Term(head :: tail) =>
      val one = quasiquote(env)(head, list = true)
      val two = quasiquote(env)(Term(tail))
      val it = if (two == Term(TUPLE :: Nil)) one else Term(APPEND :: one :: two :: Nil)
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
      panic(env, tree, "cannot unquote outside of a quasiquote")

    case Term(UNQUOTE_SPLICING :: _) =>
      panic(env, tree, "cannot unquote_splicing outside of a quasiquote")

    case Term(QUASIQUOTE :: args) => // macro
      require(env, tree, args.length == 1, s"wrong number of arguments - expected 1, got ${args.length}")
      quasiquote(env)(args(0))

    case Term(Atom("op") :: args) =>
      require(env, tree, args.length == 3, s"wrong number of arguments - expected 3, got ${args.length}")
      // todo: check for errors
      val Term(List(Atom("number"), Atom(fixityRaw), _)) = args(0)
      val Atom(name) = args(1)
      val Atom(patternRaw) = args(2)
      val fixity = fixityRaw.toInt
      val pattern = patternRaw.split(" ")
      env.parser.addMix(fixity, name, pattern)

      Term(Nil)

    case Term(Atom("core-def") :: rawArgs) => // desugar macro definition
      val args = rawArgs.map(expand(env))
      val (name, head, body) = args match {
        case Term(Atom(_1) :: _2) :: _3 :: Nil => (_1, _2, _3)
        case Term(Atom(_1) :: _2) :: Nil => (_1, _2, Term(Nil)) // forward declaration
        case _ => panic(env, tree, f"wrong number of arguments - expected 2, got ${args.length}")
      }
      val formals = head map {
        case Atom(x) => x
        case _ => panic(env, tree, f"invalid macro formals $head, expected Tuple(Term)")
      }
      env.macros += name -> Macro(formals, body, env)
      Term(Nil)

    case Term((head@Atom("core-fun")) :: args) =>
      require(env, tree, args.length == 2, s"wrong number of arguments - expected 2, got ${args.length}")

      def expandParamName(inner: Tree): Atom = inner match {
        case it@Atom(_) => it
        case _ => panic(env, inner, "bad lambda parameter name, expected Atom")
      }

      def expandParam(inner: Tree): Term = inner match {
        case it@Atom(_) => Term(it :: Term(Nil) :: Nil)
        case it@Term(Atom("core-type") :: x :: y :: Nil) => Term(expandParamName(x) :: y :: Nil)
        case _ => panic(env, inner, "bad lambda parameter, expected 'atom' or 'atom : type'")
      }

      def expandParams(inner: Tree): Term = inner match {
        case Term(Atom(",") :: tail) => Term(tail.map(expandParam))
        case Term(Nil) => Term(Term(Atom("_") :: Atom("Unit") :: Nil) :: Nil)
        case _ => Term(expandParam(inner) :: Nil)
      }

      def expandSpec(inner: Tree): Term = inner match {
        case it@Term(Atom("->") :: x :: y :: Nil) => Term(expandParams(x) :: y :: Nil)
        case it => Term(expandParams(it) :: Term(Nil) :: Nil)
      }

      val spec = expandSpec(expand(env)(args.head))
      val body = expand(env)(args(1))
      Term(Atom("core-fun!") :: spec :: body :: Nil)

    case Term((head@Atom("core-let")) :: args) =>
      require(env, tree, args.length == 2, s"wrong number of arguments - expected 2, got ${args.length}")

      def expandLeftName(inner: Tree): Atom = inner match {
        case it@Atom(_) => it
        case _ => panic(env, inner, "bad left hand side variable pattern, expected Atom")
      }

      def expandLeft(inner: Tree): Tree = inner match {
        case it@Term(Atom("core-type") :: x :: y :: Nil) => Term(expandLeftName(x) :: y :: Nil)
        case _ => Term(expandLeftName(inner) :: Term(Nil) :: Nil)
      }

      val lhs = expandLeft(expand(env)(args.head))
      val rhs = expand(env)(args(1))
      Term(Atom("core-let!") :: lhs :: rhs :: Nil)

    case Term(Atom("core-pair") :: args) =>
      require(env, tree, args.length >= 2, "wrong number of arguments - expected >= 2")
      Term(Atom("->") :: args.map(expand(env)))

    case Term(Atom("core-list") :: args) =>
      require(env, tree, args.length >= 2, "wrong number of arguments - expected >= 2")
      Term(Atom(",") :: args.map(expand(env)))

    case Term(Atom(name) :: _) if env.findMacro(name).nonEmpty =>
      val parsed = parse_once(env)(tree)._1
      val Term(_ :: tail) = parse_once(env)(tree)._1
      val Macro(params, body, local) = env.findMacro(name).get.macros(name)
      require(env, tree, params.length == tail.length, s"$name was given the wrong number of arguments - expected ${params.length}, got ${tail.length}")
      val args = tail.map(expand(env))
      (params zip args) foreach { x => local.variables += x }
      params foreach { x => local.typeOf += x -> Poly(TypeName("Term")) }
      val (exprForm, exprType) = transform(local)(expand(local)(body))
      var res1 = eval(local)(exprForm)
      val res2 = toTerm(res1)
      val res3 = expand(local)(res2)
      res3

    case Term(args) =>
      Term(args.map(expand(env)))

    case _ =>
      tree

  }

  // -- TRANSFORM -----------------------------------------------------------------

  def transformNumber(env: Env, hint: Option[Poly] = None)(
    integer: String, fraction: String
  ): (DynamicIL.Form, Poly) = {
      // todo: check if number looses precision
      val T = List("I8", "I16", "I32", "I64", "F32", "F64")
      val float = fraction.nonEmpty
      val str = if (float) f"$integer.$fraction" else integer
      val t = hint match {
        case Some(Poly(TypeName(x), _)) if T contains x => x
        case _ => if (float) "F32" else "I32"
      }
      val x: Any = t match {
        case "I8"  => str.toByte
        case "I16" => str.toShort
        case "I32" => str.toInt
        case "I64" => str.toLong
        case "F32" => str.toFloat
        case "F64" => str.toDouble
      }
      DynamicIL.Val(x) -> Poly(TypeName(t))
  }

  def transform(env: Env, hint: Option[Poly] = None)(ast: Tree): (DynamicIL.Form, Poly) = ast match {
    case Atom(name) =>
      val local = env.findVariable(name)
      require(env, ast, local.nonEmpty, f"reference to undefined variable $name")
      require(env, ast, local.get.typeOf contains name, f"variable $name has undefined type")
      val varType = local.get.typeOf(name)
      DynamicIL.Get(name) -> varType

    case Term(Atom("quote") :: x :: Nil) =>
      DynamicIL.Val(x) -> Poly(TypeName("Term"))

    case Term(Atom(",") :: h :: t) =>
      val (headForm, headType) = transform(env)(h)
      val tailForms = t.map(transform(env)).map(_._1)
      // TODO: check if list is homogenous
      val elements = (headForm :: tailForms).toArray map eval(env)
      DynamicIL.Val(elements) -> Poly(TypeCons(TypeName("Array"), headType.typ :: Nil), headType.ctx)

    case Term(Atom("core-let!") :: lhsExpr :: rhsExpr :: Nil) =>
      // check if variable is not defined
      var (lhsName, lhsType) = lhsExpr match {
        case Term(Atom(varName) :: Term(Nil) :: Nil) => varName -> None
        case Term(Atom(varName) :: varType :: Nil) => varName -> Some(toPoly(varType))
        case _ => panic(env, ast, "unknown lhs")
      }
      var (rhsForm, rhsType) = transform(env, lhsType)(rhsExpr)
      require(env, ast, !(env.typeOf contains lhsName), f"attempting to redefine the variable $lhsName")
      // check if left and right types unify

      validatePoly(env)(rhsType)
      if (lhsType.nonEmpty) {
        val (a, b) = unify(env, ast)(lhsType.get, rhsType)
        lhsType = Some(a)
        rhsType = b
      }

      env.variables(lhsName) = null
      env.typeOf(lhsName) = rhsType

      val mutable = true
      DynamicIL.Let(lhsName, rhsForm, mutable) -> rhsType

    case Term(Atom("core-set") :: Atom(name) :: rhsExpr :: Nil) =>
      // check if variable varName is defined
      val local = env.findTypeOf(name)
      require(env, ast, local.nonEmpty, f"assignment to undefined variable $name")
      val lhsType = local.get.typeOf(name)
      // check if variable varType and rhsType unifies
      val (rhsForm, rhsType) = transform(env, Some(lhsType))(rhsExpr)
      val (lhsTypeUni, rhsTypeUni) = unify(env, ast)(lhsType, rhsType)
      DynamicIL.Set(name, rhsForm) -> rhsTypeUni

    case Term(NUMBER :: Atom(integer) :: Atom(fraction) :: Nil) =>
      transformNumber(env, hint)(integer, fraction)

    case Term(STRING :: Atom(string) :: Nil) =>
      val bytes = string.getBytes(UTF_8)
      val t = Poly(TypeCons(TypeName("Array"), TypeName("I8") :: Nil))
      DynamicIL.Val(bytes) -> t

    case Term(Atom("core-fun!") :: specExpr :: bodyExpr :: Nil) =>

      def transformParam(inner: Tree) = inner match {
        case Term(Atom(name) :: Term(Nil) :: Nil) => panic(env, specExpr, "lambda parameter type inference not implemented")
        case Term(Atom(paramName) :: paramType :: Nil) => paramName -> toType(paramType)
      }

      def transformSpec(inner: Tree): (List[(String, Type)], Option[Type]) = inner match {
        case Term(Term(params) :: Term(Nil) :: Nil) => params.map(transformParam) -> None
        case Term(Term(params) :: bodyType2 :: Nil) => params.map(transformParam) -> Some(toType(bodyType2))
      }

      val (specParams, returnType) = transformSpec(specExpr)

      val local = env.extend()
      specParams foreach { case (name, typ) =>
        local.variables(name) = null
        local.typeOf(name) = Poly(typ)
      }
      val (bodyForm, bodyType) = transform(local)(bodyExpr)
      val returnType2 = returnType.getOrElse(bodyType.typ)
      val (paramNames, paramTypes) = (specParams.map(_._1), specParams.map(_._2))

      val paramsType = TypeCons(TypeName("->"), TypeCons(TypeName(","), paramTypes) :: returnType2 :: Nil)

      DynamicIL.Fun(specParams.map(_._1), bodyForm) -> Poly(paramsType)

    case Term(BLOCK :: Nil) =>
      DynamicIL.Seq(Nil) -> TypeSystem.Poly(TypeSystem.TypeName("Unit"), Nil)

    case Term(BLOCK :: args) =>
      val local = env.extend()
      val exprs = args.map(transform(local))
      val forms = exprs.map(_._1)
      val lastType = exprs.last._2
      DynamicIL.Seq(forms) -> lastType

    //case Term(QUOTE :: term :: Nil) =>

    case Term(Atom("core-loop") :: x :: y :: Nil) =>
      val ((condForm, condType), (bodyForm, _)) = (transform(env)(x), transform(env.extend())(y))
      unify(env, ast)(condType, Poly(TypeName("Bool")))
      DynamicIL.Loop(condForm, bodyForm) -> Poly(TypeName("Unit"))

    case Term(Atom("core-cond") :: x :: t :: f :: Nil) =>
      val (condForm, condType) = transform(env)(x)
      val (tForm, tType) = transform(env)(t)
      val (fForm, fType) = transform(env)(f)
      unify(env, ast)(condType, Poly(TypeName("Bool")))
      val (lhsType, rhsType) = unify(env, ast, any = true)(tType, fType)
      DynamicIL.Cond(condForm, tForm, fForm) -> rhsType

    case Term(head :: tail) =>
      val ((headForm, headType), args) = (transform(env)(head), tail.map(transform(env)))
      val (argForms, argTypes) = (args.map(_._1), args.map(_._2))
      // todo: check if headType args unify with argTypes
      DynamicIL.App(headForm, argForms) -> validatedApply(env, ast)(headType, argTypes)
  }

  // -- EVALUATE ---------------------------------------------------------------

  def eval(env: Env)(form: DynamicIL.Form): Any = form match {
    case DynamicIL.Val(x) => x

    case DynamicIL.Get(x) =>
      env.findVariable(x).get.variables(x)

    case DynamicIL.Set(x, y) =>
      env.findVariable(x).get.variables(x) = eval(env)(y)

    case DynamicIL.Let(x, y, _) =>
      env.variables(x) = eval(env)(y)

    case DynamicIL.Fun(x, y) =>
      Lambda(x, y, env)

    case DynamicIL.App(x, y) =>
      val args = y.map(eval(env))
      val res = eval(env)(x) match {
        case Lambda(params, body, local) =>
          params.zip(args).foreach(local.variables += _)
          eval(local)(body)
        case lambda =>
          lambda.asInstanceOf[BuiltinLambda](args)
      }
      res

    case DynamicIL.Seq(x) =>
      val local = env.extend()
      val res = x.map(eval(local))
      if (res.nonEmpty) res.last else ()

    case DynamicIL.Loop(x, y) =>
      val local = env.extend()
      var res = eval(local)(x)
      while (res == true) {
        eval(local)(y)
        res = eval(local)(x)
      }

    case DynamicIL.Cond(x, y, z) =>
      val local = env.extend()
      val res = eval(local)(x)
      eval(local)(if (res == true) y else z)
  }
}

