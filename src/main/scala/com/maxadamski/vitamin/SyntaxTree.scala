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

sealed trait Syntax {

  var meta: mutable.Map[String, Any] = mutable.Map()
  def tag: Tag
  def child: List[Syntax] = Nil

  def atomic: Boolean = child.nonEmpty
  def depth: Int = if (atomic) 0 else 1 + child.map(_.depth).max

  def span: Option[Span] = meta.get(Meta.Span).map(_.asInstanceOf[Span])
  def line: Option[Int] = meta.get(Meta.Line).map(_.asInstanceOf[Int])
  def char: Option[Int] = meta.get(Meta.Char).map(_.asInstanceOf[Int])
  def escaped: Boolean = meta.get(Meta.QuotedAtom).isDefined

  def fold[T](
    sum: T,
    func: Folder[Syntax, T] = foldDFS[Syntax, T] _,
    next: Syntax => List[Syntax] = nextAll _,
  )(
    f: (T, Syntax) => T,
  ): T = {
    func(this, sum, f, next)
  }

  def map(f: Syntax => Syntax): Syntax = {
    f(this)
  }

  override def toString: String = repr(this)

}


case class Leaf(tag: Tag, data: Any) extends Syntax {

}

case class Node(tag: Tag, data: List[Syntax]) extends Syntax {
  override def child: List[Syntax] = data
}

case class ParNode(id: Atom, typ: TypNode) extends Syntax {
  override def tag: Tag = Tag.Param
  override def child: List[Syntax] = List(id, typ)
}

case class ArgNode(id: Atom, value: Syntax) extends Syntax {
  override def tag: Tag = Tag.Arg
  override def child: List[Syntax] = List(id, value)
}

case class Block(expr: List[Syntax]) extends Syntax {
  override def tag: Tag = Tag.Block
  override def child: List[Syntax] = expr
}

case class Call(head: Syntax, args: List[Syntax] = List()) extends Syntax {
  override def tag: Tag = Tag.Call
  override def child: List[Syntax] = head +: args
}

case class FunNode(body: Block, ret: TypNode, par: List[ParNode]) extends Syntax {
  override def tag: Tag = Tag.Lambda
  override def child: List[Syntax] = body +: ret +: par
}

case class Quote(value: Syntax) extends Syntax {
  override def tag: Tag = Tag.Quote
  override def child: List[Syntax] = List(value)
}

case class TypNode(value: Types.Typ) extends Syntax {
  override def tag: Tag = Tag.Type
}

case class Atom(value: String) extends Syntax {
  override def tag: Tag = Tag.Atom
}

case class StrLit(value: String) extends Syntax {
  override def tag: Tag = Tag.String
}

case class IntLit(value: Int) extends Syntax {
  override def tag: Tag = Tag.Int
}

case class RealLit(value: Double) extends Syntax {
  override def tag: Tag = Tag.Real
}

object ASTUtils {

  type Fcat[A, B] = (A, B) => A
  type Walker[A] = A => List[A]

  type Folder[A, B] = (A, B, Fcat[B, A], Walker[A]) => B
  type Mapper[A, B] = (A, A => B, Walker[A]) => B

  def nextAll(node: Syntax): List[Syntax] = {
    node.child
  }

  def nextFilter(pred: Syntax => Boolean)(node: Syntax): List[Syntax] = {
    if (pred(node)) nextAll(node) else List()
  }

  def nextExcept(pred: Syntax => Boolean)(node: Syntax): List[Syntax] = {
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

  def repr(node: Syntax, level: Int = 0, multi: Boolean = false): String = {
    var lvl = level
    node match {
      case Node(tag, data) =>
        "(" + (tag.toString +: data.map(_.toString)).mkString(" ") + ")"

      case Leaf(tag, data) =>
        data.toString

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

