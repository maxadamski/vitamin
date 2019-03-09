package com.maxadamski.vitamin.runtime

import com.maxadamski.vitamin.ast.{Atom, Term, Tree}
import com.maxadamski.vitamin.{Err, Ok, Result}
import Core.{panic, require}
import com.maxadamski.vitamin.runtime.CoreType.Substitution
import PartialFunction.condOpt

object UserType {

}

object CoreType {
  sealed trait Type
  case class TC(x: Array[Type]) extends Type {
    override def toString: String = x.head.toString + x.tail.mkString("(", "  ", ")")
  }

  case class TN(x: String) extends Type {
    override def toString: String = x
  }

  case class TV(x: String) extends Type {
    override def toString: String = x
  }

  type Substitution = Map[String, Type]

  sealed trait UnifyError
  case class BadConstants(x: String, y: String) extends UnifyError
  case class BadArguments(x: Type, y: Type) extends UnifyError

  def unify(lhs: Type, rhs: Type): Result[UnifyError, Substitution]  = (lhs, rhs) match {
    case (TC(xs), TC(ys)) =>
      var sub = Map[String, Type]()
      for ((x, y) <- xs zip ys) {
        val rec = unify(x, y)
        sub ++= rec.getOrElse(return rec)
      }
      Ok(sub)

    case (TN(x), TN(y)) =>
      if (x == y)
        Ok(Map())
      else
        Err(BadConstants(x, y))

    case (TV(x), y) =>
      Ok(Map(x -> y))

    case (x, TV(y)) =>
      unify(TV(y), x)

    case (x, y) =>
      Err(BadArguments(x, y))
  }
}

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

  object TypeFun {
    def apply(x: Type, y: Type): TypeCons = TypeCons(TypeName("->"), x :: y :: Nil)
    def unapply(t: Type): Option[(Type, Type)] = condOpt(t) { case TypeCons(TypeName("->"), x :: y :: Nil) => (x, y) }
  }

  object TypeTup {
    def apply(x: List[Type]): TypeCons = TypeCons(TypeName(","), x)
    def unapply(t: Type): Option[List[Type]] = condOpt(t) { case TypeCons(TypeName(","), x) => x }
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
      require(env, typ, local.nonEmpty, "undefined type")
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
    require(env, typ, arity == given, f"type constructor takes $arity arguments, but was given $given")
  }

  def validatePoly(env: Env)(poly: Poly): Unit = validateType(env)(poly.ctx, poly.typ)

  def convertPoly(env: Env, ast: Tree)(poly: Poly): CoreType.Type = {
    val vars = poly.ctx flatMap { case forall(TypeName(x)) => Some(x); case _ => Nil }

    def convert(typ: Type): CoreType.Type = typ match {
      case TypeName(x) =>
        if (vars contains x)
          CoreType.TV(x)
        else
          CoreType.TN(x)

      case TypeCons(x, y) =>
        val args = (x :: y) map convert
        CoreType.TC(args.toArray)
    }

    convert(poly.typ)
  }

  def convertCore(typ: CoreType.Type): Type = typ match {
    case CoreType.TN(x) => TypeName(x)
    case CoreType.TV(x) => TypeName(x)
    case CoreType.TC(x) =>
      val args = x.toList map convertCore
      TypeCons(args.head, args.tail)
  }

  def substituteType(sub: Substitution)(typ: Type): Type = typ match {
    case it@TypeName(x) =>
      if (sub contains x)
        convertCore(sub(x))
      else
        it

    case it@TypeCons(h, t) =>
      val h2 = substituteType(sub)(h)
      val t2 = t map substituteType(sub)
      TypeCons(h2, t2)
  }

  def unify(env: Env, ast: Tree, any: Boolean = false)(x: Poly, y: Poly): (Poly, Poly) = {
    val (a, b) = (convertPoly(env, ast)(x), convertPoly(env, ast)(y))
    val sub = CoreType.unify(a, b)
    if (sub.isErr) {
      if (any) return (Poly(TypeName("Any")), Poly(TypeName("Any")))
      panic(env, ast, s"unification of $a and $b failed with error ${sub.getError}")
    }

    val subf = substituteType(sub.get) _
    val (u, v) = (subf(x.typ), subf(y.typ))
    (Poly(u), Poly(v))
  }

  def validatedApply(env: Env, ast: Tree)(f: Poly, args: List[Poly]): Poly = (f, args) match {
    case (t, Nil) =>
      t
    case (Poly(TypeFun(x, y), ctx), _) =>
      val argTuple = Poly(TypeTup(args.map(_.typ)), args.flatMap(_.ctx))
      val (u, v) = unify(env, ast)(Poly(x, ctx), argTuple)
      Poly(y, ctx)
  }
}
