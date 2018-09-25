package com.maxadamski.vitamin

import scala.annotation.tailrec
import java.util

import Tag.Tag
import ASTUtils._


case class Span(start: Int, stop: Int)

object Tag extends Enumeration {
  val Pragma, Lambda, Block, Call, Arg, Flat, Array,
      Let, Set, Quote,
      Atom, Int, Real, String, Null = Value
  type Tag = Value

}

object Meta {
  val Span = "span"
  val Text = "text"
  val QuotedAtom = "quoted_atom"
}

sealed trait Expr

case class Node(data: Iterable[AST]) extends Expr

case class Leaf(data: Any) extends Expr

case class AST(tag: Tag, data: Expr, meta: Map[String, Any] = Map()) {

  def atomic: Boolean = tag match {
    case Tag.Atom | Tag.Int | Tag.Real | Tag.String => true
    case _ => false
  }

  def child: Iterable[AST] = data match {
    case Node(children) => children.filterNot(it => it.tag == Tag.Null)
    case Leaf(_) => Seq()
  }

  def depth: Int = data match {
    case Node(children) => 1 + (if (children.isEmpty) 0 else children.map(_.depth).max)
    case Leaf(_) => 0
  }

  def fold[T](
    sum: T,
    func: Folder[AST, T] = foldDFS[AST, T] _,
    next: AST => List[AST] = nextAll _,
  )(
    f: (T, AST) => T,
  ): T = {
    func(this, sum, f, next)
  }

  def map(
    func: Mapper[AST, AST] = mapPostOrder,
    next: AST => List[AST] = nextAll _,
  )(
    f: AST => AST
  ): AST = {
    func(this, f, next)
  }

  override def toString: String = repr(this)

}

object ASTUtils {

  type Fcat[A, B] = (A, B) => A
  type Walker[A] = A => List[A]

  type Folder[A, B] = (A, B, Fcat[B, A], Walker[A]) => B
  type Mapper[A, B] = (A, A => B, Walker[A]) => B

  def nextAll(node: AST): List[AST] = {
    node.child.toList
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

  def mapPostOrder(node: AST, f: AST => AST, next: Walker[AST]): AST = {
    val a = new util.Stack[AST]
    val b = new util.Stack[AST]
    a.push(node)

    while (!a.empty) {
      val top = a.pop()
      b.push(top)
      next(top).foreach(a.push)
    }

    val c = new util.Stack[AST]()
    while (!b.empty) {
      val top = b.pop()
      top match {
        case AST(_, Node(oldChildren), _) =>
          val children = oldChildren.toList.indices
            .map(_ => c.pop()).filterNot(it => it.tag == Tag.Null).reverse
          c.add(f(top.copy(data = Node(children))))
        case AST(_, Leaf(_), _) =>
          c.add(f(top))
      }
    }

    c.pop()
  }

  def repr(node: AST, level: Int = 0, multi: Boolean = false): String = {
    var lvl = level
    node match {
      case AST(Tag.Lambda, Node(data), _) =>
        val bodyStr = repr(data.last, lvl, multi)
        val initStr = data.dropRight(1).map(repr(_, lvl, multi)).mkString(" ")
        s"(:λ $initStr $bodyStr)"
      case AST(Tag.Call, Node(data), _) =>
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
    }
  }

}

