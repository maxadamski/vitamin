package com.maxadamski.vitamin

import java.io.RandomAccessFile


class RuntimeException(val message: String) extends Exception

class ParserException(val message: String) extends Exception

object Source {
  val END = "\33[0m"
  val BOLD = "\33[1m"
  val UNDER = "\33[4m"
  val BLACK = "\33[30m"
  val RED = "\33[31m"
  val GREEN = "\33[32m"
  val YELLOW = "\33[33m"
  val BLUE = "\33[34m"
  val VIOLET = "\33[35m"
  val BEIGE = "\33[36m"
  val WHITE = "\33[37m"

  def readSpan(file: RandomAccessFile, span: Span): String = {
    val bytes = new Array[Byte](span.stop - span.start + 1)
    file.seek(span.start)
    file.readFully(bytes)
    new String(bytes)
  }

  import util.control.Breaks._

  // returns the span, expanded to contain the entire line
  def lineSpan(file: RandomAccessFile, span: Span): Span = {
    val EOL = Array('\n', '\r')
    var start = span.start
    var stop = span.stop

    breakable {
      while (true) {
        file.seek(start)
        if (EOL.contains(file.readByte())) {
          start += 1
          break
        }
        if (start <= 0) {
          break
        }
        start -= 1
      }
    }

    breakable {
      while (true) {
        file.seek(stop)
        if (EOL.contains(file.readByte())) {
          stop -= 1
          break
        }
        if (stop >= file.length - 1) {
          break
        }
        stop += 1
      }
    }

    Span(start, stop)
  }

  def readExcerpt(filePath: String, span: Span): (String, Span) = {
    val file = new RandomAccessFile(filePath, "r")
    val span2 = lineSpan(file, span)
    val string = readSpan(file, span2)
    file.close()
    (string, Span(span.start - span2.start, span.stop - span2.start + 1))
  }

  def lineNumber(line: Int, format: String): String = {
    format.format(line) + "|"
  }

  def lineError(error: Boolean): String = {
    if (error) s"$BOLD$RED>$END" else " "
  }

  def highlightedColumns1(source: String, start: Int, stop: Int): String = {
    val squiggles = " " * start + "^" * (stop - start)
    s"$source\n$BOLD$RED$squiggles$END\n"
  }

  // the caller is responsible for checking bounds
  def highlightedColumns2(source: String, start: Int, stop: Int): String = {
    if (start == 0 && stop == 0) return source
    val prefix = source.substring(0, start)
    val error = source.substring(start, stop)
    val suffix = source.substring(stop, source.length)
    s"$prefix$UNDER$RED$error$END$suffix"
  }

  def highlightedLine(
    source: String, format: String, error: Boolean,
    y: Int, x0: Int, x1: Int
  ): String = {
    val number = lineNumber(y, format)
    number + lineError(error) + " " + highlightedColumns2(source, x0, x1)
  }

  def highlightedSource(lines: Array[(String, Span)], start: Int): String = {
    val stop = start + lines.length
    val numbers = Range(start, stop)
    val format = "%0" + stop.toString.length + "d"

    val formatted = (numbers zip lines).map { case (y, (line, span)) =>
      val error = !(span.start == 0 && span.stop == 0) || (span.start == -1 && span.stop == -1)
      highlightedLine(line, format, error, y, span.start, span.stop)
    }

    formatted.mkString("\n")
  }

  def errorExcerpt(filePath: String, span: Span, lineAnchor: Int): String = {
    val (source, relativeSpan) = readExcerpt(filePath, span)
    val lines = source.lines.toArray
    val spec = if (lines.length == 1)
      lines.map(_ -> relativeSpan)
    else
      lines.map(_ -> Span(-1, -1))
    highlightedSource(spec, lineAnchor)
  }
}

object Report {
  def error(
    name: String, comment: String, hints: Array[String],
    file: String, code: Option[String], line: Option[Int], char: Option[Int],
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
        sum + s"hint: ${it.lines.mkString(hintpad)}\n"
      }
    }

    result
  }

  def compileError(
    c: Ctx, name: String, comment: String,
    hints: Array[String] = Array(),
    node: Syntax = null, high: Syntax = null,
  ): String = {
    val node2 = if (node != null) node else c.node
    val high2 = if (high != null) high else node2
    val file = c.file

    val (span, line, char) = (node2.span, node2.line, node2.char)
    val code = (span, line) match {
      case (Some(sp), Some(ln)) => Some(Source.errorExcerpt(file, sp, ln))
      case _ => None
    }

    error(name, comment, hints, file, code, line, char)
  }

  def error__parser__null_unexpected_token(c: Ctx, token: Token): String =
    compileError(
      c, "syntax error",
      s"expected a primary expression or prefix operator, but got '${token.value}'")

  def error__parser__left_unexpected_token(c: Ctx, token: Token): String =
    compileError(
      c, "syntax error",
      s"expected an infix or suffix operator, but got '${token.value}'")

  def error__parser__null_bad_precedence(c: Ctx, t: Token, l: Token): String =
    compileError(
      c, "syntax error",
      s"violated precedence contract: '${t.key}' cannot follow '${l.key}' in this context.\n" +
        s"check operator associativity and precedence relations.",
      hints = Array(
        "a prefix operator of higher precedence may precede a prefix operator of lower precedence.\n" +
          "fix trivially by reversing the operator order",
        "the same non-associative prefix operator may be used in succession.\n" +
          "fix trivially by putting the subexpression in parentheses",
      ))

  def error__parser__left_bad_precedence(c: Ctx, t: Token, l: Token): String =
    compileError(
      c, "syntax error",
      s"violated precedence contract: '${t.key}' cannot follow '${l.key}' in this context.\n" +
        s"check operator associativity and precedence relations.",
      hints = Array(
        "the same non-associative infix/suffix operator may be used in succession\n" +
          "fix trivially by putting the subexpression in parentheses",
      ))

  def error__parser__null_not_registered(c: Ctx, t: Token): String =
    compileError(
      c, "syntax error",
      s"'${t.key}' is not a prefix operator, and cannot be used as such.")

  def error__parser__left_not_registered(c: Ctx, t: Token): String =
    compileError(
      c, "syntax error",
      s"'${t.key}' is not an infix or suffix operator, and cannot be used as such.")

  def error__parser__unexpected_eof(c: Ctx): String =
    compileError(
      c, "syntax error",
      s"expression ended unexpectedly.")

  def error__type__call_mismatch(c: Ctx, name: String, args: Array[String], got: Array[String]): String =
    compileError(
      c, "type error",
      s"'$name' argument types do not match the function signature\n" +
      s"expected: ${args.mkString(", ")}\n" +
      s"but was:  ${got.mkString(", ")}\n"
    )

  def error__eval__set_undefined(c: Ctx, name: String): String = {
    compileError(c, "runtime error",
      s"attempting to assign to an undefined variable '$name'.")
  }

  def error__eval__get_undefined(c: Ctx, name: String): String = {
    compileError(c, "runtime error",
      s"attempting to use an undefined variable '$name'.")
  }

  def error__eval__let_defined(c: Ctx, name: String): String = {
    compileError(c, "runtime error",
      s"attempting to redefine a variable '$name' in current scope.")
  }

  def error__eval__div_zero(c: Ctx): String = {
    compileError(c, "runtime error",
      s"cannot divide by zero.")
  }
}

