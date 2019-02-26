package com.maxadamski.vitamin.debug

import com.maxadamski.vitamin.ast._
import com.maxadamski.vitamin.runtime._
import com.maxadamski.vitamin.parser._
import Report.compileError

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

  def compileError(
    c: Env, name: String, comment: String,
    hints: Array[String] = Array(),
    node: Tree = null, high: Tree = null
  ): String = {
    val node2 = if (node != null) node else c.node
    val high2 = if (high != null) high else node2
    val file = c.file
    val line = node2.rule.map(_.line)
    val char = node2.rule.map(_.char)
    val code = node2.rule.map(rule => Source.errorExcerpt(file, rule.span, rule.line))
    error(name, comment, hints, file, code, line, char)
  }
}

object Error {
  def error__parser__null_unexpected_token(c: Env, token: Token): String =
    compileError(
      c, "syntax error",
      s"expected a primary expression or prefix operator, but got '${token.value}'")

  def error__parser__left_unexpected_token(c: Env, token: Token): String = {
    val token_desc = if (token.key == PrattParser.LIT) "primary expression" else "prefix operator"
    compileError(
      c, "syntax error",
      s"expected an infix or suffix operator, but got $token_desc '${token.value}'")
  }

  def error__parser__null_bad_precedence(c: Env, t: Token, l: Token): String = {
    compileError(
      c, "syntax error",
      s"violated precedence contract: ${t.typeString} '${t.value}' cannot follow ${l.typeString} '${l.value}' in this context.\n" +
        s"check operator associativity and precedence relations.",
      hints = Array(
        "a prefix operator of higher precedence may precede a prefix operator of lower precedence.\n" +
          "fix trivially by reversing the operator order",
        "the same non-associative prefix operator may be used in succession.\n" +
          "fix trivially by putting the subexpression in parentheses"
      ))
  }

  def error__parser__left_bad_precedence(c: Env, t: Token, l: Token): String =
    compileError(
      c, "syntax error",
      s"violated precedence contract: ${t.typeString} '${t.value}' cannot follow ${l.typeString} '${l.value}' in this context.\n" +
        s"check operator associativity and precedence relations.",
      hints = Array(
        "the same non-associative infix/suffix operator may be used in succession\n" +
          "fix trivially by putting the subexpression in parentheses"
      ))

  def error__parser__null_not_registered(c: Env, t: Token): String =
    compileError(
      c, "syntax error",
      s"cannot use ${t.typeString} '${t.value}' as a prefix operator.")

  def error__parser__left_not_registered(c: Env, t: Token): String =
    compileError(
      c, "syntax error",
      s"cannot use ${t.typeString} '${t.value}' as an infix or suffix operator.")

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
