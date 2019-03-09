package com.maxadamski.vitamin.debug

import java.io.RandomAccessFile

import com.maxadamski.vitamin.ast._
import com.maxadamski.vitamin.runtime._
import com.maxadamski.vitamin.parser2._
import Report.compileError
import com.maxadamski.vitamin.lexer.Span

object Report {
  def error(
    name: String, comment: String, hints: Array[String],
    file: String, code: Option[String], line: Option[Int], char: Option[Int]
  ): String = {
    val head = s"-- ${name.toUpperCase} "
    val loc = if (line.isDefined && char.isDefined) s":${line.get}:${char.get}" else ""
    val tail = s" [$file$loc]"
    val padding = "-" * (80 - head.length - tail.length)
    val hintpad = "\n" + " " * 6

    var result = s"$head$padding$tail\n\n$comment\n"

    if (code.isDefined) {
      result += s"\n${code.get}\n"
    }

    if (hints.nonEmpty) {
      result += hints.fold("\n") { case (sum, it) =>
        sum + s"hint: ${it.split("\\r?\\n").mkString(hintpad)}\n"
      }
    }

    result
  }

  def compileError2(ctx: Env, term: Tree = null, name: String, body: String,
            hint: Array[String] = Array()): String = {
    val file = ctx.file
    term.span.getOrElse(term.compSpan) match {
      case Some(Span((b0, y0, x0), (b1, y1, x1))) =>
        val f = new RandomAccessFile(file, "r")
        val r = Source.expandedRange(f, Source.ByteRange(b0, b1))
        val text = Source.read(f, r)
        var lines = text.split(raw"[\r]?\n[\r]?")
        lines = Formatter.highlightLines(lines, 0, x0 - 1, y1 - y0, x1 - 1)
        lines = Formatter.formatLines(lines, y0, y1)
        val code = lines.mkString("\n")
        error(name, body, hint, file, Some(code), Some(y0), Some(x0))

      case _ =>
        error(name, body, hint, file, None, None, None)
    }
  }

  def compileError(
    ctx: Env, name: String, comment: String,
    hints: Array[String] = Array()
  ): String = {
    compileError2(ctx, ctx.node, name, comment, hints)
  }
}

object Error {
  def error__parser__null_unexpected_token(c: Env, token: Tree): String =
    compileError(
      c, "syntax error",
      s"expected a primary expression or prefix operator, but got '$token'")

  def error__parser__left_unexpected_token(c: Env, token: Tree): String = {
    compileError(
      c, "syntax error",
      s"expected an infix or suffix operator, but got '$token'")
  }

  def error__parser__null_bad_precedence(c: Env, t: Tree, l: Tree): String = {
    compileError(
      c, "syntax error",
      s"violated precedence contract: '$t' cannot follow '$l' in this context.\n" +
        s"check operator associativity and precedence relations.",
      hints = Array(
        "a prefix operator of higher precedence may precede a prefix operator of lower precedence.\n" +
          "fix trivially by reversing the operator order",
        "the same non-associative prefix operator may be used in succession.\n" +
          "fix trivially by putting the subexpression in parentheses"
      ))
  }

  def error__parser__left_bad_precedence(c: Env, t: Tree, l: Tree): String =
    compileError(
      c, "syntax error",
      s"violated precedence contract: '$t' cannot follow '$l' in this context.\n" +
        s"check operator associativity and precedence relations.",
      hints = Array(
        "the same non-associative infix/suffix operator may be used in succession\n" +
          "fix trivially by putting the subexpression in parentheses"
      ))

  def error__parser__null_not_registered(c: Env, t: Tree): String =
    compileError(
      c, "syntax error",
      s"cannot '$t' as a prefix operator.")

  def error__parser__left_not_registered(c: Env, t: Tree): String =
    compileError(
      c, "syntax error",
      s"cannot use '$t' as an infix or suffix operator.")

  def error__parser__bad_mix(c: Env, name: String, expected: Tree, actual: Tree): String =
    compileError(
      c, "syntax error",
      s"mixfix operator $name expected '$expected', but got '$actual'.")

  def error__parser__unexpected_eof(c: Env): String =
    compileError(
      c, "syntax error",
      s"expression ended unexpectedly.")

  def error__type__call_mismatch(c: Env, name: String, args: Array[String], got: Array[String]): String =
    compileError(
      c, "type error",
      s"'$name' argument types do not match the function signature\n" +
        s"expected: ${args.mkString(", ")}\n" +
        s"but was:  ${got.mkString(", ")}\n"
    )

  def error__eval__set_undefined(c: Env, name: String): String = {
    compileError(c, "runtime error",
      s"attempting to assign to an undefined variable '$name'.")
  }

  def error__eval__get_undefined(c: Env, name: String): String = {
    compileError(c, "runtime error",
      s"attempting to use an undefined variable '$name'.")
  }

  def error__eval__let_defined(c: Env, name: String): String = {
    compileError(c, "runtime error",
      s"attempting to redefine a variable '$name' in current scope.")
  }

  def error__eval__div_zero(c: Env): String = {
    compileError(c, "runtime error",
      s"cannot divide by zero.")
  }
}
