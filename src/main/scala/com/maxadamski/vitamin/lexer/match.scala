package com.maxadamski.vitamin.lexer

import com.maxadamski.vitamin.Utils.stob

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

object Matchers {
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

  val EOS = Token(TokenType.EOS, Array(stob("EOS")), None)
  val BEG = Token(TokenType.BEG, Array(stob("BEG")), None)
  val END = Token(TokenType.END, Array(stob("END")), None)
  val MODE_ESC = "ESC"
  val MODE_COM = "COM"
}
