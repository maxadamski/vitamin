package com.maxadamski.vitamin.lexer

import scala.collection.mutable.ArrayBuffer
import scala.util.control.Breaks._
import Utils._
import TokenType.TokenType

object TokenType extends Enumeration {
  type TokenType = Value
  val Atom, Com, Num, Str, Spec = Value
}

case class Span(a: (Int, Int), b: (Int, Int)) {
  override def toString = f"${a._1}:${a._2}-${b._1}:${b._2}"
}

case class Token(t: TokenType, x: Array[Array[Byte]], span: Option[Span] = None) {
  override def toString = {
    val compStr = x.map(b => f"'${btoe(b)}'").mkString(" ")
    val spanStr = if (span.nonEmpty) f" ${span.get}" else ""
    f"<$t $compStr$spanStr>"
  }
}

sealed trait Matcher

case class MSeq(bytes: Byte*) extends Matcher {
  override def toString = bytes.map(b => f"'${b.toChar}'").mkString(" & ")
  def matches(x: Array[Byte]): Boolean = bytes.toArray sameElements x
  val length: Int = bytes.length
}

case class MAlt(bytes: Byte*) extends Matcher {
  override def toString = bytes.map(b => f"'${b.toChar}'").mkString(" | ")
  def matches(x: Byte): Boolean = bytes contains x
}

case class MFun(lambda: Byte => Boolean) extends Matcher {
  def matches(x: Byte): Boolean = lambda(x)
}

case class Mode(name: String, pos: Int, line: Int, char: Int) {
  override def toString = f"<mode $name line $line:$char>"
}

object Utils {
  import reflect.runtime.universe.{Literal, Constant}
  import java.nio.charset.StandardCharsets.UTF_8

  def escape(raw: String): String = Literal(Constant(raw)).toString.drop(1).dropRight(1)
  def btoe(x: Array[Byte]): String = escape(btos(x))
  def btos(x: Array[Byte]): String = new String(x, UTF_8)
  def stob(x: String): Array[Byte] = x.getBytes(UTF_8)
  def tok(t: TokenType, b: Array[Byte], s: Span) = Token(t, Array(b), Some(s))
  def tok(t: TokenType, b: Array[Array[Byte]], s: Span) = Token(t, b, Some(s))
}

class Lexer {
  var mode: List[Mode] = List()
  var buf: Array[Byte] = Array()
  var line: Int = 1
  var char: Int = 1
  var pos: Int = 0
  var len: Int = 0

  def can_peek(n: Int): Boolean = n <= available
  def available: Int = len - pos
  def isEmpty: Boolean = pos == len
  def nonEmpty: Boolean = !isEmpty
  def point: (Int, Int) = (line, char)

  def next1(): Byte = next(1).head
  def peek1: Byte = peek(1).headOption getOrElse '\0'
  def peek2: Array[Byte] = peek(2)

  def curr: Char = peek1.toChar

  def pushMode(name: String): Unit = {
    mode +:= Mode(name, pos, line, char)
  }

  def popMode(): String = {
    val m = mode.head
    mode = mode.tail
    m.name
  }

  def topMode: String = {
    mode.headOption.map(_.name).getOrElse("")
  }

  def peek(n: Int): Array[Byte] = {
    //if (!can_peek(n)) throw new Exception(f"lexer wanted to get '$n' bytes but the buffer has length '$len'")
    buf.slice(pos, (pos + n) min len)
  }

  def next(n: Int): Array[Byte] = {
    val res = peek(n)
    pos += n
    char += 1
    res foreach { b =>
      if (b == '\n') {
        line += 1
        char = 1
      }
    }
    res
  }

  def tokenize(bytes: Array[Byte], lex: Lexer => Array[Token]): Array[Token] = {
    buf = bytes
    len = bytes.length
    var tokens = ArrayBuffer[Token]()
    while (available > 0) {
      tokens ++= lex(this)
    }
    tokens.toArray
  }
}

object Lexer {
  val CR     = MAlt('\r')
  val ESC    = MAlt('\\')
  val EOF    = MAlt('\0')
  val DOT    = MAlt('.')
  val SEMI   = MAlt(';')
  val COM1   = MSeq('/', '/')
  val COM2   = MSeq('/', '*')
  val COM2_R = MSeq('*', '/')
  val STR    = MAlt('`', '"')
  val STR1_1 = MSeq('"')
  val STR1_2 = MSeq('`')
  val STR2_1 = MSeq('"', '"', '"')
  val WS     = MAlt('\t', '\n', '\r', '\f', ' ')
  val NL     = MAlt('\n', '\r')
  val LPAR   = MAlt('(', '[', '{')
  val RPAR   = MAlt(')', ']', '}')
  val SEP    = MAlt('.', ',', ';')
  val WSEP   = MAlt(':')
  val SSEP   = MAlt('.', ',', ';', '(', ')', '[', ']', '{', '}', '"', '`', '\t', '\n', '\r', '\f', '\0', ' ')
  val EXP1   = MAlt('e', 'E')
  val EXP2   = MAlt('p', 'P')
  val ALPHA  = MFun(b => b >= 'A' && b <= 'Z' || b >= 'a' && b <= 'z')
  val DIGIT  = MFun(b => b >= '0' && b <= '9')
  val NUM    = DIGIT
  val NUM_T  = MFun(b => b == '_' || (DIGIT matches b))

  val EOS = Token(TokenType.Spec, Array(stob("EOS")), None)
  val MODE_ESC = "ESC"
  val MODE_COM = "COM"

  def MODE_PAR(b: Byte): String = b match {
    case '(' | ')' => "("
    case '[' | ']' => "["
    case '{' | '}' => "{"
  }

  def lexVitaminC(it: Lexer): Array[Token] = {
    val (b1, b2) = (it.peek1, it.peek2)
    if      (NL   matches b1) lexNL(it)
    else if (WS   matches b1) lexWS(it)
    else if (LPAR matches b1) lexLPAR(it)
    else if (RPAR matches b1) lexRPAR(it)
    else if (SEMI matches b1) lexSEMI(it)
    else if (SEP  matches b1) lexSEP(it)
    else if (STR  matches b1) lexSTR(it)
    else if (NUM  matches b1) lexNUM(it)
    else if (COM1 matches b2) lexCOM1(it)
    else if (COM2 matches b2) lexCOM2(it)
    else if (ESC  matches b1) lexESC(it)
    else if (EOF  matches b1) lexEOF(it)
    else                      lexATOM(it)
  }

  def lexATOM(it: Lexer): Array[Token] = {
    var atom: ArrayBuffer[Byte] = ArrayBuffer()
    var weak: Option[Token] = None
    var (start, end) = (it.point, it.point)
    breakable {
      while (true) {
        if (SSEP matches it.peek1) break
        if (it.can_peek(2) && (WSEP matches it.peek1)) {
          val b = it.peek2
          if (SSEP matches b(1)) {
            val sepStart = it.point
            val buf = Array(it.next1())
            weak = Some(tok(TokenType.Atom, buf, Span(sepStart, it.point)))
            break
          }
        }
        atom :+= it.next1()
        end = it.point
      }
    }
    var tokens = Array[Token]()
    if (atom.nonEmpty) tokens :+= tok(TokenType.Atom, atom.toArray, Span(start, end))
    if (weak.nonEmpty) tokens :+= weak.get
    tokens
  }

  def lexSEP(it: Lexer): Array[Token] = {
    val start = it.point
    val b = it.next1()
    Array(tok(TokenType.Atom, Array(b), Span(start, it.point)))
  }

  def lexSEMI(it: Lexer): Array[Token] = {
    val beg = it.point
    while (SEMI matches it.peek1) it.next1()
    Array(EOS.copy(span = Some(Span(beg, beg))))
  }

  def lexWS(it: Lexer): Array[Token] = {
    while (WS matches it.peek1) it.next1()
    Array()
  }

  def lexNUM(it: Lexer): Array[Token] = {
    val start = it.point
    val part1 = lexDIGITS_10(it)
    val part2 = if (DOT matches it.peek1) {
      it.next1()
      lexDIGITS_10(it)
    } else {
      Array[Byte]()
    }
    Array(tok(TokenType.Num, Array(part1, part2), Span(start, it.point)))
  }

  private def lexDIGITS_10(it: Lexer): Array[Byte] = {
    val buffer = ArrayBuffer[Byte]()
    buffer ++= it.next(1)
    while (NUM_T matches it.peek1) buffer ++= it.next(1)
    buffer.toArray
  }


  def lexSTR(it: Lexer): Array[Token] = {
    val start = it.point
    val buffer = lexSTR_1_3(it)
    Array(tok(TokenType.Str, Array(buffer), Span(start, it.point)))
  }

  private def lexSTR_1_3(it: Lexer): Array[Byte] = {
    val next3 = it.peek(3)
    if (STR2_1 matches next3) return lexSTR_N(it, STR2_1, STR2_1, multi = true)

    val next1 = it.peek(1)
    if (STR1_1 matches next1) return lexSTR_N(it, STR1_1, STR1_1)
    if (STR1_2 matches next1) return lexSTR_N(it, STR1_2, STR1_2)

    throw new Exception(s"unknown string delimiter '${next1(0).toChar}'")
  }

  private def lexSTR_N(it: Lexer, beg: MSeq, end: MSeq, multi: Boolean = false): Array[Byte] = {
    // ld/rd: left/right delimiter
    val n = end.length
    val buffer = ArrayBuffer[Byte]()
    buffer ++= it.next(beg.length)
    breakable {
      while (true) {
        if (end matches it.peek(n)) break
        val next1 = it.peek1
        if ((NL matches next1) && !multi) break
        if (ESC matches next1) buffer ++= it.next(1)
        if (it.isEmpty)
          throw new Exception("end of file while string is open")
        buffer ++= it.next(1)
      }
    }
    buffer ++= it.next(end.length)
    buffer.toArray
  }

  // Comment1 and Comment2

  def lexCOM1(it: Lexer): Array[Token] = {
    var buffer = ArrayBuffer[Byte]()
    val start = it.point
    buffer ++= it.next(2)
    while (!(NL matches it.peek1)) buffer ++= it.next(1)
    Array(tok(TokenType.Com, buffer.toArray, Span(start, it.point)))
  }

  def lexCOM2(it: Lexer): Array[Token] = {
    val buffer = ArrayBuffer[Byte]()
    val start = it.point
    buffer ++= it.next(2)
    it.pushMode(MODE_COM)
    while (it.topMode == MODE_COM && it.nonEmpty) {
      val next2 = it.peek2
      if (COM2 matches next2) {
        buffer ++= it.next(2)
        it.pushMode(MODE_COM)
      } else if (COM2_R matches next2) {
        buffer ++= it.next(2)
        if (it.topMode != MODE_COM)
          throw new Exception(f"extraneous comment delimiter '*/', current mode is '${it.topMode}'")
        it.popMode()
      } else {
        buffer ++= it.next(1)
      }
    }
    Array(tok(TokenType.Com, buffer.toArray, Span(start, it.point)))
  }

  def lexNL(it: Lexer): Array[Token] = {
    var tokens = Array[Token]()
    val start = it.point
    lexNLCR(it)
    if (it.mode.isEmpty || it.topMode == "{") {
      // newline means semicolon if a block is open
      tokens :+= EOS.copy(span = Some(Span(start, start)))
      while (NL matches it.peek1)
        lexNLCR(it)
    } else if (it.topMode == MODE_ESC) {
      it.popMode()
    }
    tokens
  }

  private def lexNLCR(it: Lexer): Unit = {
    if (CR matches it.peek1) it.next1()
    it.next1()
    if (CR matches it.peek1) it.next1()
  }

  def lexLPAR(it: Lexer): Array[Token] = {
    val b = it.peek1
    val start = it.point
    it.pushMode(MODE_PAR(b))
    it.next1()
    Array(tok(TokenType.Atom, Array(b), Span(start, it.point)))
  }

  def lexRPAR(it: Lexer): Array[Token] = {
    val b = it.peek1
    val start = it.point
    val m = MODE_PAR(b)
    if (it.mode.isEmpty)
      throw new Exception(f"unmatched parenthesis '${b.toChar}' at ${it.line}:${it.char}")
    if (it.topMode != m)
      throw new Exception(f"unmatched parenthesis '${b.toChar}' at ${it.line}:${it.char}, currently '${it.mode.head.name}' at ${it.mode.head.line}:${it.mode.head.char} is open")
    it.next1()
    it.popMode()
    Array(tok(TokenType.Atom, Array(b), Span(start, it.point)))
  }

  def lexESC(it: Lexer): Array[Token] = {
    it.next1()
    //it.pushMode(MODE_ESC)
    if (NL matches it.peek1) lexNL(it)
    Array()
  }

  def lexEOF(it: Lexer): Array[Token] = {
    if (List("(", "{", "[") contains it.topMode)
      throw new Exception(f"unmatched parenthesis ${it.mode.head.name} at the end of file")
    Array()
  }
}
