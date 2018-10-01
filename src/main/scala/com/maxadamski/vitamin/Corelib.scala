package com.maxadamski.vitamin

import Types._
import Functions.Builtin
import ASTUtils._

object Corelib {

  def register(ctx: Ctx): Unit = {
    def addFun(name: String, typ: Fun, body: List[Any] => Any): Unit = {
      val k = ctx.mangleFun(name, arity(typ), typ)
      val v = Builtin(typ, body)
      ctx.let(k, v)
    }

    def addVal(name: String, typ: AType, value: Any): Unit = {
      ctx.let(name, value)
    }

    addVal("Int", TYPE, INT)
    addVal("Str", TYPE, STR)
    addVal("Bool", TYPE, BOOL)
    addVal("Real", TYPE,  REAL)
    addVal("Expr", TYPE,  EXPR)
    addVal("Void", TYPE,  VOID)

    addVal("()", VOID, OBJ_VOID)
    addVal("nil", NIL, OBJ_NIL)
    addVal("true", BOOL, true)
    addVal("false", BOOL, false)
    addVal("BS", STR, "\b")
    addVal("HT", STR, "\t")
    addVal("NL", STR, "\n")
    addVal("CR", STR, "\r")

    addFun("not", mkFun(BOOL, BOOL),       { case List(x: Boolean) => !x })
    addFun("and", mkFun(BOOL, BOOL, BOOL), { case List(x: Boolean, y: Boolean) => x && y })
    addFun("or",  mkFun(BOOL, BOOL, BOOL), { case List(x: Boolean, y: Boolean) => x || y })

    addFun("+",   mkFun(INT, INT, INT),  { case List(x: Int, y: Int) => x + y })
    addFun("-",   mkFun(INT, INT, INT),  { case List(x: Int, y: Int) => x + y })
    addFun("*",   mkFun(INT, INT, INT),  { case List(x: Int, y: Int) => x + y })
    addFun("/",   mkFun(INT, INT, REAL), { case List(x: Int, y: Int) => x.toDouble / y.toDouble })
    addFun("div", mkFun(INT, INT, INT),  { case List(x: Int, y: Int) => x / y })
    addFun("mod", mkFun(INT, INT, INT),  { case List(x: Int, y: Int) => x % y })
    addFun(">=",  mkFun(INT, INT, BOOL), { case List(x: Int, y: Int) => x >= y })
    addFun("<=",  mkFun(INT, INT, BOOL), { case List(x: Int, y: Int) => x <= y })
    addFun(">",   mkFun(INT, INT, BOOL), { case List(x: Int, y: Int) => x > y })
    addFun("<",   mkFun(INT, INT, BOOL), { case List(x: Int, y: Int) => x < y })

    addFun("+",   mkFun(REAL, REAL, REAL), { case List(x: Double, y: Double) => x + y })
    addFun("-",   mkFun(REAL, REAL, REAL), { case List(x: Double, y: Double) => x + y })
    addFun("*",   mkFun(REAL, REAL, REAL), { case List(x: Double, y: Double) => x + y })
    addFun("/",   mkFun(REAL, REAL, REAL), { case List(x: Double, y: Double) => x / y })
    addFun(">=",  mkFun(REAL, REAL, BOOL), { case List(x: Double, y: Double) => x >= y })
    addFun("<=",  mkFun(REAL, REAL, BOOL), { case List(x: Double, y: Double) => x <= y })
    addFun(">",   mkFun(REAL, REAL, BOOL), { case List(x: Double, y: Double) => x > y })
    addFun("<",   mkFun(REAL, REAL, BOOL), { case List(x: Double, y: Double) => x < y })

    addFun("==",  mkFun(INT, INT, BOOL),   { case List(x: Int, y: Int) => x == y })
    addFun("!=",  mkFun(INT, INT, BOOL),   { case List(x: Int, y: Int) => x != y })
    addFun("==",  mkFun(REAL, REAL, BOOL), { case List(x: Double, y: Double) => x == y })
    addFun("!=",  mkFun(REAL, REAL, BOOL), { case List(x: Double, y: Double) => x != y })
    addFun("==",  mkFun(BOOL, BOOL, BOOL), { case List(x: Boolean, y: Boolean) => x == y })
    addFun("!=",  mkFun(BOOL, BOOL, BOOL), { case List(x: Boolean, y: Boolean) => x != y })
    addFun("==",  mkFun(STR, STR, BOOL),   { case List(x: String, y: String) => x == y })
    addFun("!=",  mkFun(STR, STR, BOOL),   { case List(x: String, y: String) => x != y })

    addFun("Real", mkFun(INT, REAL),   { case List(x: Int) => x.toDouble })

    addFun("Int",  mkFun(REAL, INT),   { case List(x: Double)  => x.toInt })
    addFun("Int",  mkFun(BOOL, INT),   { case List(x: Boolean) => if (x) 1 else 0 })

    addFun("Str",  mkFun(INT,  STR),   { case List(x: Any) => x.toString })
    addFun("Str",  mkFun(REAL, STR),   { case List(x: Any) => x.toString })
    addFun("Str",  mkFun(BOOL, STR),   { case List(x: Any) => x.toString })

    addFun("Core_print", mkFun(STR, VOID), { case List(x: String) => print(x) })
    addFun("Core_quote", mkFun(EXPR, EXPR), { case List(x: Syntax) => Quote(x) })
  }

}
