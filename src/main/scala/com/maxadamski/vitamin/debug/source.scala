package com.maxadamski.vitamin.debug

import util.control.Breaks._
import java.io.RandomAccessFile

import com.maxadamski.vitamin.ast.Span

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
    val lines = source.split("\\r?\\n")
    val spec = if (lines.length == 1)
      lines.map(_ -> relativeSpan)
    else
      lines.map(_ -> Span(0, 0))
    highlightedSource(spec, lineAnchor)
  }
}

