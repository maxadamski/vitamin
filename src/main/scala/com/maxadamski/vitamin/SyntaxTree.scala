package com.maxadamski.vitamin

import scala.annotation.tailrec
import scala.collection.mutable

import AST.Tag.Tag
import ASTUtils._
import AST._

case class Span(start: Int, stop: Int)

object AST {

  type MetaMap = mutable.Map[String, Any]

  def nullMeta: MetaMap = mutable.Map[String, Any]()

  object Tag extends Enumeration {
    val Lambda, Fun, Block, Arg, Param,
    Let, Set, Call, Quote,
    AnyMatch, VarMatch, TupMatch,
    ConType, FunType,
    Array, Atom, Int, Real, String,
    Flat, Null = Value
    type Tag = Value

  }

  object Meta {
    val Span = "span"
    val Text = "text"
    val Escaped = "escaped"
    val Line = "line"
    val Char = "char"
    val Directive = "pragma"
    val Annotation = "annotation"
    val Rest = "rest"
  }

  sealed trait Tree {

    var tag: Tag
    var meta: MetaMap

    def child: List[Tree]

    def atomic: Boolean

    def depth: Int = if (atomic) 0 else 1 + child.map(_.depth).max

    def span: Option[Span] = meta.get(Meta.Span).map(_.asInstanceOf[Span])

    def line: Option[Int] = meta.get(Meta.Line).map(_.asInstanceOf[Int])

    def char: Option[Int] = meta.get(Meta.Char).map(_.asInstanceOf[Int])

    def getBoolMeta(key: String): Boolean = meta.get(key).isDefined

    def isEscaped: Boolean = getBoolMeta(Meta.Escaped)

    def isDirective: Boolean = getBoolMeta(Meta.Directive)

    def isAnnotation: Boolean = getBoolMeta(Meta.Annotation)

    def isRest: Boolean = getBoolMeta(Meta.Rest)

    def fold[T](sum: T, func: Folder[Tree, T] = foldDFS[Tree, T] _, next: Tree => List[Tree] = nextAll _)(f: (T, Tree) => T): T = {
      func(this, sum, f, next)
    }

    def map(next: Tree => List[Tree] = it => it.child)(f: Tree => Tree): Tree = f(this match {
      case term: Node => term.copy(data = next(term).map(_.map(next)(f)))
      case _ => this
    })

    override def toString: String = repr(this)

  }


  case class Node(var tag: Tag, var data: List[Tree], var meta: MetaMap = nullMeta) extends Tree {
    def child: List[Tree] = data

    def atomic: Boolean = false
  }

  case class Leaf(var tag: Tag, var value: Any, var meta: MetaMap = nullMeta) extends Tree {
    def child: List[Tree] = List()

    def atomic: Boolean = true
  }

  object Lambda {
    def unapply(term: Node): Option[(Tree, Tree)] = term match {
      case Node(Tag.Lambda, pattern :: chunk :: Nil, _) => Some((pattern, chunk))
      case _ => None
    }
  }

  object Call {
    def unapply(term: Node): Option[(Tree, List[Tree])] = term match {
      case Node(Tag.Call, head :: tail, _) => Some((head, tail))
      case _ => None
    }
  }

  object Atom {
    def apply(value: String): Leaf = Leaf(Tag.Atom, value)

    def unapply(leaf: Leaf): Option[String] = leaf match {
      case Leaf(Tag.Atom, value: String, _) => Some(value)
      case _ => None
    }
  }

  object Zero extends Leaf(Tag.Null, Nil)

}

object ASTUtils {

  type Fcat[A, B] = (A, B) => A
  type Walker[A] = A => List[A]

  type Folder[A, B] = (A, B, Fcat[B, A], Walker[A]) => B
  type Mapper[A, B] = (A, A => B, Walker[A]) => B

  def nextAll(node: Tree): List[Tree] = {
    node.child
  }

  def nextFilter(pred: Tree => Boolean)(node: Tree): List[Tree] = {
    if (pred(node)) nextAll(node) else List()
  }

  def nextExcept(pred: Tree => Boolean)(node: Tree): List[Tree] = {
    if (!pred(node)) nextAll(node) else List()
  }

  def foldDFS[A, B](node: A, sum: B, f: Fcat[B, A], next: Walker[A]): B = {
    @tailrec
    def go(stack: List[A], cur: A, acc: B): B = (next(cur), stack) match {
      case (head :: tail, _) => go(tail ++ stack, head, f(acc, cur))
      case (Nil, head :: tail) => go(tail, head, f(acc, cur))
      case (_, Nil) => acc
    }

    go(Nil, node, sum)
  }

  def foldBFS[A, B](node: A, sum: B, f: Fcat[B, A], next: Walker[A]): B = {
    @tailrec
    def go(stack: List[A], cur: A, acc: B): B = (next(cur), stack) match {
      case (head :: tail, _) => go(stack ++ tail, head, f(acc, cur))
      case (Nil, head :: tail) => go(tail, head, f(acc, cur))
      case (_, Nil) => acc
    }

    go(Nil, node, sum)
  }

  def leafRepr(node: Leaf): String = {
    node.value match {
      case s: String => "'" + s + "'"
      case d: Double => d.toString
      case i: Int => i.toString
      case value => value.toString
    }
  }

  def repr(node: Tree, level: Int = 0, multi: Boolean = false): String = {
    node match {
      case Zero => "⊥"
      case Atom(value) => value
      case Node(Tag.Arg, List(value, Zero), _) => repr(value)
      case leaf: Leaf => leafRepr(leaf)
      case Node(tag, data, _) =>
        val items = (tag :: data).map(_.toString)
        "(" + items.mkString(" ") + ")"
    }
  }
}

