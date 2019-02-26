package com.maxadamski.vitamin.runtime

object Corelib {

//  def register(ctx: Ctx): Unit = {
//    def addFun(name: String, typ: Typ, body: List[Any] => Any): Unit = {
//      val k = ctx.mangleFun(name, typ.arity, typ)
//      val v = Builtin(typ, body)
//      ctx.let(k, typ, v, const = true)
//    }
//
//    def addVal(name: String, typ: Typ, value: Any): Unit = {
//      ctx.let(name, typ, value)
//    }
//
//    genericRegister(addFun, addVal)
//  }
//
//  def registerTypeEnv(env: Transform.Env): Unit = {
//    def addFun(name: String, typ: Typ, body: List[Any] => Any): Unit = {
//      env.addFunc(name, typ)
//    }
//
//    def addVal(name: String, typ: Typ, value: Any): Unit = {
//      env.addVari(name, typ, const = false)
//    }
//
//    genericRegister(addFun, addVal)
//  }
//
//  def genericRegister(
//    addFun: (String, Typ, List[Any] => Any) => Unit,
//    addVal: (String, Typ, Any) => Unit,
//  ): Unit = {
//    addVal("Int", TYPE, INT)
//    addVal("Str", TYPE, STR)
//    addVal("Bool", TYPE, BOOL)
//    addVal("Real", TYPE, REAL)
//    addVal("Expr", TYPE, EXPR)
//    addVal("Void", TYPE, VOID)
//
//    addVal("()", VOID, OBJ_VOID)
//    addVal("nil", NIL, OBJ_NIL)
//    addVal("true", BOOL, true)
//    addVal("false", BOOL, false)
//    addVal("BS", STR, "\b")
//    addVal("HT", STR, "\t")
//    addVal("NL", STR, "\n")
//    addVal("CR", STR, "\r")
//
//    addFun("add_int", Fun(Tup(INT, INT), INT), { case List(x: Int, y: Int) => x + y })
//
//    addFun("and", Fun(Tup(BOOL, BOOL), BOOL), { case List(x: Boolean, y: Boolean) => x && y })
//    addFun("or", Fun(Tup(BOOL, BOOL), BOOL), { case List(x: Boolean, y: Boolean) => x || y })
//    addFun("+", Fun(Tup(INT, INT), INT), { case List(x: Int, y: Int) => x + y })
//    addFun("-", Fun(Tup(INT, INT), INT), { case List(x: Int, y: Int) => x - y })
//    addFun("*", Fun(Tup(INT, INT), INT), { case List(x: Int, y: Int) => x * y })
//    addFun("/", Fun(Tup(INT, INT), REAL), { case List(x: Int, y: Int) => x.toDouble / y.toDouble })
//    addFun("div", Fun(Tup(INT, INT), INT), { case List(x: Int, y: Int) => x / y })
//    addFun("mod", Fun(Tup(INT, INT), INT), { case List(x: Int, y: Int) => x % y })
//    addFun(">=", Fun(Tup(INT, INT), BOOL), { case List(x: Int, y: Int) => x >= y })
//    addFun("<=", Fun(Tup(INT, INT), BOOL), { case List(x: Int, y: Int) => x <= y })
//    addFun(">", Fun(Tup(INT, INT), BOOL), { case List(x: Int, y: Int) => x > y })
//    addFun("<", Fun(Tup(INT, INT), BOOL), { case List(x: Int, y: Int) => x < y })
//    addFun("+", Fun(Tup(I64, I64), I64), { case List(x: Long, y: Long) => x + y })
//    addFun("-", Fun(Tup(I64, I64), I64), { case List(x: Long, y: Long) => x - y })
//    addFun("*", Fun(Tup(I64, I64), I64), { case List(x: Long, y: Long) => x * y })
//    addFun("div", Fun(Tup(I64, I64), I64), { case List(x: Long, y: Long) => x / y })
//    addFun("mod", Fun(Tup(I64, I64), I64), { case List(x: Long, y: Long) => x % y })
//    addFun("+", Fun(Tup(REAL, REAL), REAL), { case List(x: Double, y: Double) => x + y })
//    addFun("-", Fun(Tup(REAL, REAL), REAL), { case List(x: Double, y: Double) => x - y })
//    addFun("*", Fun(Tup(REAL, REAL), REAL), { case List(x: Double, y: Double) => x * y })
//    addFun("/", Fun(Tup(REAL, REAL), REAL), { case List(x: Double, y: Double) => x / y })
//    addFun(">=", Fun(Tup(REAL, REAL), BOOL), { case List(x: Double, y: Double) => x >= y })
//    addFun("<=", Fun(Tup(REAL, REAL), BOOL), { case List(x: Double, y: Double) => x <= y })
//    addFun(">", Fun(Tup(REAL, REAL), BOOL), { case List(x: Double, y: Double) => x > y })
//    addFun("<", Fun(Tup(REAL, REAL), BOOL), { case List(x: Double, y: Double) => x < y })
//    addFun("==", Fun(Tup(INT, INT), BOOL), { case List(x: Int, y: Int) => x == y })
//    addFun("!=", Fun(Tup(INT, INT), BOOL), { case List(x: Int, y: Int) => x != y })
//    addFun("==", Fun(Tup(REAL, REAL), BOOL), { case List(x: Double, y: Double) => x == y })
//    addFun("!=", Fun(Tup(REAL, REAL), BOOL), { case List(x: Double, y: Double) => x != y })
//    addFun("==", Fun(Tup(BOOL, BOOL), BOOL), { case List(x: Boolean, y: Boolean) => x == y })
//    addFun("!=", Fun(Tup(BOOL, BOOL), BOOL), { case List(x: Boolean, y: Boolean) => x != y })
//    addFun("==", Fun(Tup(STR, STR), BOOL), { case List(x: String, y: String) => x == y })
//    addFun("!=", Fun(Tup(STR, STR), BOOL), { case List(x: String, y: String) => x != y })
//    addFun("Real", Fun(INT, REAL), { case List(x: Int) => x.toDouble })
//    addFun("Real", Fun(STR, REAL), { case List(x: String) => x.toDouble })
//    addFun("Int", Fun(REAL, INT), { case List(x: Double) => x.toInt })
//    addFun("Int", Fun(I64, INT), { case List(x: Long) => x.toInt })
//    addFun("Int", Fun(BOOL, INT), { case List(x: Boolean) => if (x) 1 else 0 })
//    addFun("Int", Fun(STR, INT), { case List(x: String) => x.toInt })
//    addFun("I64", Fun(INT, I64), { case List(x: Int) => x.toLong })
//    addFun("Str", Fun(STR, STR), { case List(x: Any) => x.toString })
//    addFun("Str", Fun(I64, STR), { case List(x: Any) => x.toString })
//    addFun("Str", Fun(INT, STR), { case List(x: Any) => x.toString })
//    addFun("Str", Fun(REAL, STR), { case List(x: Any) => x.toString })
//    addFun("Str", Fun(BOOL, STR), { case List(x: Any) => x.toString })
//    addFun("not", Fun(BOOL, BOOL), { case List(x: Boolean) => !x })
//    addFun("-", Fun(INT, INT), { case List(x: Int) => -x })
//    addFun("-", Fun(I64, I64), { case List(x: Long) => -x })
//    addFun("-", Fun(REAL, REAL), { case List(x: Double) => -x })
//
//    addFun("Core_print", Fun(ANY, VOID), { case List(x: Any) => print(x.toString) })
//    addFun("Core_input", Fun(VOID, STR), { case List() => System.console.readLine })
//    addFun("Core_time", Fun(VOID, I64), { case List() => java.lang.System.currentTimeMillis() })
//  }

}
