package com.maxadamski.vitamin.parser

object LexerByteClasses {
  type Class = Byte => Boolean
  type ListClass = List[Byte]

  def NL: Class = _ == '\n'
  def CR: Class = _ == '\r'
  def TAB: Class = _ == '\t'
  def SPC: Class = _ == ' '
  def ESC: Class = _ == '\\'
  def EOF: Class = _ == '\0'
  def DOT: Class = _ == '.'
  def SEMI: Class = _ == ';'
  def HASH: Class = _ == '#'
  def QUOTE: Class = _ == '"'
  def QUASI: Class = _ == '`'

  def ALPHA      : Class = x => x >= 'a' && x <= 'z' || x >= 'A' && x <= 'Z'
  def DIGIT      : Class = x => x >= '0' && x <= '9'
  def WHITE      : Class = x => x == '\t' || x == ' '
  def ATOM_HEAD  : Class = x => ALPHA(x) || List('_', '#', '@').contains(x)
  def ATOM_TAIL  : Class = x => ALPHA(x) || DIGIT(x) || List('_', '!', '?').contains(x)
  def SYMB_HEAD  : Class = x => ":<>=.*/~^$&|!?%+-" contains x
  def SYMB_TAIL  : Class = x => SYMB_HEAD(x) || ("@#" contains x)
  def LPAREN     : Class = x => x == '('
  def SEPARATOR  : Class = x => x == ',' || x == ';'

  def NOT_NEWLINE: Class = x => x != '\n' && x != '\r'
  def DIGITS1_H  : Class = x => DIGIT(x)
  def DIGITS1_T  : Class = x => DIGIT(x) || x == '_'
  def EXP        : Class = x => x == 'e' || x == 'E'

  val COM1     : ListClass = List('/', '/')
  val COM2_L   : ListClass = List('/', '*')
  val COM2_R   : ListClass = List('*', '/')
  val STR1     : ListClass = List('"')
  val STR3     : ListClass = List('`')
  val STR2     : ListClass = List('"', '"', '"')
}

class Lexer {
  sealed trait Token

  case class NormalToken(x: Array[Byte]) extends Token {
    override def toString: String = f"'${btos(x)}'"
  }
  case class StringToken(x: Option[Array[Byte]], y: Array[Byte]) extends Token
  case class NumberToken(integer: Array[Byte], fractional: Option[Array[Byte]]) extends Token

  private def btos(x: Array[Byte]): String = new String(x, java.nio.charset.StandardCharsets.UTF_8)
  private def stob(x: String): Array[Byte] = x.getBytes(java.nio.charset.StandardCharsets.UTF_8)

  private def tok(x: List[Byte]) = NormalToken(x.toArray)
  private def tok(x: Byte) = NormalToken(Array(x))
  private def tok(x: String) = NormalToken(stob(x))

  val List(lp, lb, lc) = List('(', '[', '{').map(_.toByte)
  val List(rp, rb, rc) = List(')', ']', '}').map(_.toByte)

  val lgroup: Map[Byte, String] = Map(lp -> "()", lb -> "[]", lc -> "{}")
  val rgroup: Map[Byte, String] = Map(rp -> "()", lb -> "[]", rc -> "{}")
  var mode: List[String] = List()
  var next: List[Byte] = List()
  var done: List[Byte] = List()

  // -- Byte stream operations

  private def peek(i: Int = 1): Option[Byte] = {
    assert(i > 0)
    if (i - 1 < next.size) Some(next(i - 1)) else None
  }

  private def peekn(n: Int): List[Byte] = {
    assert(n > 0)
    if (n <= next.size) next.slice(0, n) else Nil
  }

  private def eat(): Option[Byte] = next match {
    case head :: tail => next = tail; done :+= head; Some(head)
    case Nil => None
  }

  private def eatn(n: Int): List[Byte] = {
    val res = peekn(n)
    next = next.drop(res.length)
    done ++= res
    res
  }

  import LexerByteClasses._

  // -- Common matchers

  private def matches(matcher: Class, x: Option[Byte]): Boolean = x match {
    case Some(b) if matcher(b) => true
    case _ => false
  }

  private def matches(matcher: Class): Boolean = matches(matcher, peek())

  private def matches(matcher: ListClass, n: Int): Boolean = peekn(n) == matcher

  private def eatOne(matcher: Byte => Boolean): Option[Byte] = {
    if (matches(matcher, peek())) eat() else None
  }

  private def eatStar(matcher: Byte => Boolean): List[Byte] = {
    var buffer = List[Byte]()
    while (matches(matcher, peek())) buffer :+= eat().get
    buffer
  }

  private def eatPlus(matcher: Byte => Boolean): List[Byte] = eatOne(matcher) match {
    case Some(head) => head :: eatStar(matcher)
    case _ => Nil
  }

  // -- Custom lexer code

  def tokens(bytes: List[Byte]): List[Token] = {
    next = bytes
    var tokens = List[Token]()
    while (next.nonEmpty) {
      var Some(b) = peek()
      if (NL(b) || CR(b)) {
        lexNewline()
        if (mode.isEmpty || mode.head == "{}") {
          // newline means semicolon if a block is open
          tokens :+= tok("EOS")
          while (matches(NL) || matches(CR)) lexNewline()
        } else if (mode.head == "ESC") {
          // pop escape mode
          mode = mode.tail
        }
      } else if (ESC(b)) {
        eat()
        mode +:= "ESC"
      } else if (lgroup contains b) {
        eat()
        mode +:= lgroup(b)
        tokens :+= tok(b)
      } else if (rgroup contains b) {
        eat()
        val m = rgroup(b)
        if (mode.head.isEmpty)
          throw new Exception(f"unmatched parenthesis $m")
        if (mode.head != m)
          throw new Exception(f"unmatched parenthesis $m, currently ${mode.head} is open")
        mode = mode.tail
        tokens :+= tok(b)
        if (matches(LPAREN)) tokens :+= tok("CAL")
      } else if (EOF(b)) {
        // check if all parentheses have been closed
        if (mode.nonEmpty && List("()", "{}", "[]").contains(mode.head))
          throw new Exception(f"parentheses not closed ${mode.head} despite end of file")
      } else if (WHITE(b)) {
        // ignore whitespace
        eatStar(WHITE)
      } else if (matches(COM1, 2)) {
        tokens :+= tok(lexComment1())
      } else if (matches(COM2_L, 2)) {
        tokens :+= tok(lexComment2())
      } else if (QUOTE(b)) {
        tokens :+= StringToken(None, lexString().toArray)
      } else if (QUASI(b)) {
        tokens :+= StringToken(None, lexStringN(1, STR3, STR3).toArray)
      } else if (DIGIT(b)) {
        tokens :+= lexNumber()
      } else if (SEPARATOR(b)) {
        tokens :+= tok(eat().get)
      } else if (SYMB_HEAD(b)) {
        val atom = eatn(1) ++ eatStar(SYMB_TAIL)
        tokens :+= tok(atom)
        if (matches(LPAREN)) tokens :+= tok("CAL")
      } else if (ATOM_HEAD(b)) {
        // new atom
        val atom = eatn(1) ++ eatStar(ATOM_TAIL)
        // if the atom is actually a sigil, also lex string
        if (matches(STR1, 1)) {
          tokens :+= StringToken(Some(atom.toArray), lexString().toArray)
        } else {
          tokens :+= tok(atom)
          if (matches(LPAREN)) tokens :+= tok("CAL")
        }
      } else {
        throw new Exception(f"unknown token ${b.toChar}")
      }
    }
    tokens
  }

  private def lexNewline(): List[Byte] = {
    val cr = eatOne(CR)
    val nl = eatOne(NL)
    // consume CR? NL CR?
    //if (cr.nonEmpty && nl.isEmpty)
    //  throw new Exception("line ending - NL must follow CR")
    eatOne(CR)
    Nil
  }

  private def lexString(): List[Byte] = {
    if (matches(STR2, 3))
      lexStringN(3, STR2, STR2, multiline = true)
    else
      lexStringN(1, STR1, STR1)
  }

  private def lexStringN(DC: Int, LD: ListClass, RD: ListClass, multiline: Boolean = false): List[Byte] = {
    // ld/rd: left/right delimiter
    // dc: length of delimiter
    var buffer = eatn(DC)
    // peek().get is unsafe!
    while (!matches(RD, DC) && (multiline || matches(NOT_NEWLINE))) {
      if (matches(ESC)) buffer :+= eat().get
      val b = eat().getOrElse(
        throw new Exception("end of file while string is open")
      )
      buffer :+= b
    }
    buffer ++= eatn(DC)
    buffer
  }

  private def lexNumber(): Token = {
    val part1 = lexDigits1().toArray
    val was_dot = eatOne(DOT).nonEmpty
    val part2 = if (was_dot) Some(lexDigits1().toArray) else None
    NumberToken(part1, part2)
  }

  private def lexDigits1(): List[Byte] = {
    eat().get :: eatStar(DIGITS1_T)
  }

  private def lexComment1(): List[Byte] = {
    eat().get :: eat().get :: eatStar(NOT_NEWLINE)
  }

  private def lexComment2(): List[Byte] = {
    var level = 1
    var buffer = eat().get :: eat().get :: Nil
    while (level > 0 && next.nonEmpty) {
      if (matches(COM2_L, 2)) {
        buffer ++= eat().get :: eat().get :: Nil
        level += 1
      } else if (matches(COM2_R, 2)) {
        buffer ++= eat().get :: eat().get :: Nil
        level -= 1
        if (level < 0)
          throw new Exception(f"mismatched comment delimiter '*/'")
      } else {
        buffer :+= eat().get
      }
    }
    buffer
  }
}
