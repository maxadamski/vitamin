package com.maxadamski.vitamin

import reflect.runtime.universe.{Literal, Constant}
import java.nio.charset.StandardCharsets.UTF_8

object Utils {
  def escape(raw: String): String = Literal(Constant(raw)).toString.drop(1).dropRight(1)
  def btoe(x: Array[Byte]): String = escape(btos(x))
  def btos(x: Array[Byte]): String = new String(x, UTF_8)
  def stob(x: String): Array[Byte] = x.getBytes(UTF_8)
}

sealed trait Result[+Error, +Value] {
  def isErr: Boolean = this match {
    case Err(_) => true
    case _ => false
  }

  def isOk: Boolean = !isErr

  def getError: Error = this.asInstanceOf[Err[Error]].value
  def get: Value = this.asInstanceOf[Ok[Value]].value

  def toOption: Option[Value] = this match {
    case Err(_) => None
    case Ok(x) => Some(x)
  }

  def map[A](f: Value => A): Result[Error, A] = this match {
    case Err(x) => Err(x)
    case Ok(x) => Ok(f(x))
  }

  def mapErr[A](f: Error => A): Result[A, Value] = this match {
    case Err(x) => Err(f(x))
    case Ok(x) => Ok(x)
  }

  def getOrElse[A >: Value](f: => A): A = this match {
    case Err(_) => f
    case Ok(x) => x
  }
}

case class Ok[Value](value: Value) extends Result[Nothing, Value]
case class Err[Error](value: Error) extends Result[Error, Nothing]
