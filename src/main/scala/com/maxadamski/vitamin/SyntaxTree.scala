package com.maxadamski.vitamin

import scala.annotation.tailrec
import java.util

import Tag.Tag
import ASTUtils._

import scala.collection.mutable


case class Span(start: Int, stop: Int)

object Tag extends Enumeration {
  val Pragma, Lambda, Type, Block, Call, Arg, Flat, Param, Array,
      Let, Set, Quote,
      Atom, Int, Real, String, Null = Value
  type Tag = Value

}

object Meta {
  val Span = "span"
  val Text = "text"
  val QuotedAtom = "quoted_atom"
  val Line = "line"
  val Char = "char"
}


sealed trait AST {

  var meta: mutable.Map[String, Any] = mutable.Map()
  def tag: Tag
  def child: List[AST] = Nil

  def atomic: Boolean = child.nonEmpty
  def depth: Int = if (atomic) 0 else 1 + child.map(_.depth).max

  def span: Option[Span] = meta.get(Meta.Span).map(_.asInstanceOf[Span])
  def line: Option[Int] = meta.get(Meta.Line).map(_.asInstanceOf[Int])
  def char: Option[Int] = meta.get(Meta.Char).map(_.asInstanceOf[Int])
  def escaped: Boolean = meta.get(Meta.QuotedAtom).isDefined

  def fold[T](
    sum: T,
    func: Folder[AST, T] = foldDFS[AST, T] _,
    next: AST => List[AST] = nextAll _,
  )(
    f: (T, AST) => T,
  ): T = {
    func(this, sum, f, next)
  }

  def map(next: AST => List[AST] = it => it.child)(f: AST => AST): AST = {
    val res = this match {
      case term: Term =>
        term.copy(data = next(term).map(_.map(next)(f)))
      case _ =>
        this
    }
    f(res)
  }

  override def toString: String = repr(this)

}


sealed trait ASTNode extends AST

case class Term(tag: Tag, var data: List[AST]) extends ASTNode {

  // Arg : {value: Expr, name: Atom|Zero}
  def isArg = tag == Tag.Arg && data.length == 2

  // Par : {name: Atom, typ: Type}
  def isPar = tag == Tag.Param && data.length == 2

  // Fun : {body: Expr, ret: Type, par: Type*}
  def isFun = tag == Tag.Lambda && data.length >= 2

  // Call : {callee: Expr, arg: Arg*}
  def isCall = tag == Tag.Call && data.length >= 1

  // Expr : {value: Expr}
  def isQuote = tag == Tag.Quote && data.length == 1

  override def child: List[AST] = data

  override def atomic: Boolean = false

}

object Term {

  def apply(tag: Tag, data: AST*)(implicit d: DummyImplicit) =
    new Term(tag, data.toList)

  def makeCall(callee: AST, arg: List[AST]): AST = {
    Term(Tag.Call, callee :: arg)
  }

}


sealed trait ASTLeaf extends AST

case class Leaf(tag: Tag, value: Any) extends ASTLeaf

case class Atom(value: String) extends ASTLeaf {
  def tag: Tag = Tag.Atom
}

object Zero extends ASTLeaf {
  def tag: Tag = Tag.Null
}








object ASTUtils {

  type Fcat[A, B] = (A, B) => A
  type Walker[A] = A => List[A]

  type Folder[A, B] = (A, B, Fcat[B, A], Walker[A]) => B
  type Mapper[A, B] = (A, A => B, Walker[A]) => B

  def nextAll(node: AST): List[AST] = {
    node.child
  }

  def nextFilter(pred: AST => Boolean)(node: AST): List[AST] = {
    if (pred(node)) nextAll(node) else List()
  }

  def nextExcept(pred: AST => Boolean)(node: AST): List[AST] = {
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

  /*
  def mapPostOrder(node: Syntax, f: Syntax => Syntax, next: Walker[Syntax]): Syntax = {
    val a = new util.Stack[Syntax]
    val b = new util.Stack[Syntax]
    a.push(node)

    while (!a.empty) {
      val top = a.pop()
      b.push(top)
      next(top).foreach(a.push)
    }

    val c = new util.Stack[Syntax]()
    while (!b.empty) {
      val top = b.pop()
      top match {
        case Node(_, oldChildren) =>
          val children = oldChildren
            .indices
            .map(_ => c.pop())
            .filterNot(it => it.tag == Tag.Null)
            .reverse

          c.add(f( .copy(data = Node(children))))
        case Leaf(_, _) =>
          c.add(f(top))
      }
    }

    c.pop()
  }
  */

  def leafRepr(node: Leaf): String = {
    node.value match {
      case s: String => "'" + s + "'"
      case d: Double => d.toString
      case i: Int => i.toString
      case value => value.toString
    }
  }

  def repr(node: AST, level: Int = 0, multi: Boolean = false): String = {
    //var lvl = level
    node match {
      case Term(Tag.Arg, List(value, Zero)) => repr(value)
      case leaf: Leaf => leafRepr(leaf)
      case Atom(value) => value
      case Zero => "⊥"
      case Term(tag, data) =>
        val items = (tag :: data).map(_.toString)
        "(" + items.mkString(" ") + ")"



        /*
      case FunNode(body, ret, par) =>
        val d = data.toList
        val bodyStr = repr(data.last, lvl, multi)
        val initStr = data.dropRight(1).map(repr(_, lvl, multi)).mkString(" ")
        s"(:λ $initStr $bodyStr)"
      case Call(data, Nil) =>
        val d = data.map(repr(_, lvl, multi)).mkString(" ")
        s"(.$d)"
      case AST(Tag.Quote, Node(data +: _), _) =>
        s"'$data"
      case AST(tag, Node(data), _) if node.depth > 4 =>
        lvl += 1
        val sep = if (multi) "\n" + "\t" * lvl else ""
        val suf = if (multi) "\n" + "\t" * (lvl - 1) else ""
        val args = sep + data.map(repr(_, lvl, multi)).mkString(" " + sep) + suf
        s"(:$tag $args)"
      case AST(tag, Node(data), _) =>
        val args = data.map(repr(_, lvl, multi)).mkString(" ")
        s"(:$tag $args)"
      case AST(Tag.String, Leaf(data), _) =>
        s"'$data'"
      case AST(_, Leaf(data), _) =>
        s"$data"
        */
    }
  }
}

