package com.maxadamski.vitamin.debug

import util.control.Breaks._
import java.io.RandomAccessFile

import com.maxadamski.vitamin.lexer.Span


object Source {
  case class ByteRange(a: Int, b: Int)

  // read bytes from file in range [a, b)
  def read(file: RandomAccessFile, range: ByteRange): String = {
    val bytes = new Array[Byte](range.b - range.a + 1)
    file.seek(range.a)
    file.readFully(bytes)
    new String(bytes)
  }

  // expands byte range to contain whole lines
  def expandedRange(file: RandomAccessFile, range: ByteRange): ByteRange = {
    var ByteRange(start, stop) = range
    val EOL = Array('\n', '\r')

    breakable {
      while (true) {
        file.seek(start)
        if (EOL contains file.readByte) {
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
        if (EOL contains file.readByte) {
          stop -= 1
          break
        }
        if (stop >= file.length - 1) {
          break
        }
        stop += 1
      }
    }

    ByteRange(start, stop)
  }
}

object Formatter {
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

  def formatLines(lines: Array[String], y0: Int, y1: Int): Array[String] = {
    // add a line number to each line
    val fmt = "%0" + y1.toString.length + "d"
    val numbers = (y0 to y1).map(y => fmt format y)
    (numbers zip lines).map(x => f"${x._1} | ${x._2}").toArray
  }

  def highlightLines(lines: Array[String], y0: Int, x0: Int, y1: Int, x1: Int): Array[String] = {
    // highlight all chars in lines if in range
    if (y0 == y1) {
      val a = lines(y0).substring(0, x0)
      val b = lines(y0).substring(x0, x1)
      val c = lines(y0).substring(x1)
      lines(y0) = f"$a$BOLD$UNDER$b$END$c"
    } else {

    }
    lines
  }

  /*
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

  def highlightedSource(lines: Array[(String, ByteRange)], start: Int): String = {
    val stop = start + lines.length
    val numbers = Range(start, stop)
    val format = "%0" + stop.toString.length + "d"

    val formatted = (numbers zip lines).map { case (y, (line, range)) =>
      val error = !(start == 0 && stop == 0) || (start == -1 && stop == -1)
      highlightedLine(line, format, error, y, start, stop)
    }

    formatted.mkString("\n")
  }

  def errorExcerpt(filePath: String, range: ByteRange, lineAnchor: Int): String = {
    val (source, relativeSpan) = readExcerpt(filePath, span)
    val lines = source.split("\\r?\\n")
    val spec = if (lines.length == 1)
      lines.map(_ -> relativeSpan)
    else
      lines.map(_ -> Span((0, 0, 0), (0, 0, 0)))
    highlightedSource(spec, lineAnchor)
  }
  */
}

