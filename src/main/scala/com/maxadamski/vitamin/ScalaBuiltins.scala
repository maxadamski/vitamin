package com.maxadamski.vitamin

import java.io.{OutputStream, InputStream, FileOutputStream, FileInputStream}
import java.nio.charset.StandardCharsets.UTF_8
import runtime.TypeSystem._

object ScalaBuiltins {
  def btos(x: Array[Byte]): String = new String(x, UTF_8)
  def stob(x: String): Array[Byte] = x.getBytes(UTF_8)
  def withStr(a: Array[Byte])(f: String => String): Array[Byte] = stob(f(btos(a)))
  def mapStr[T](a: Array[Byte])(f: String => T): Unit = f(btos(a))

  def mkTypes(x: String): List[TypeName] = x.split(' ').map(TypeName).toList
  //def fun(args: Type*): Type = args.toList.reduceRight { (sum, x) => TypeCons(TypeName("->"), List(sum, x)) }
  def fun(args: Type*): Type = TypeCons(TypeName("->"), tup(args.dropRight(1): _*) :: args.last :: Nil)
  def tup(args: Type*) = TypeCons(TypeName(","), args.toList)
  def arr(x: Type): TypeCons = TypeCons(array, x :: Nil)
  def tn(x: String): TypeName = TypeName(x)
  def tc(x: Type, y: Type*): TypeCons = TypeCons(x, y.toList)

  def mkIdFun(name: String, n: Int)(x: List[TypeName]): List[(String, Poly)] =
    x.map { t => f"sys_${name}_${t.x}" -> Poly(fun(Range(0, n).map(_ => t): _*)) }

  def mkRetFun(name: String, ret: TypeName)(x: List[TypeName]): List[(String, Poly)] =
    x.map { t => f"sys_${name}_${t.x}" -> Poly(fun(t, t, ret)) }

  // monomorphic types
  private val aa = tn("a")
  private val bottom = tn("bottom")
  private val array = tn("Array")

  // built-in types
  private val integers = mkTypes("I8 I16 I32 I64")
  private val floating = mkTypes("F32 F64")
  private val specials = mkTypes("Bool Unit")
  private val process = tn("Process")
  private val ostream = tn("OStream")
  private val istream = tn("IStream")
  private val array_a = Poly(tc(array, aa), forall(aa) :: Nil)
  private val term = tn("Term")

  // convenience
  private val List(i8, i16, i32, i64) = integers
  private val List(f32, f64)  = floating
  private val List(bool, unit) = specials
  private val num = integers ++ floating
  private val eq = integers ++ floating ++ specials

  val typesKind1: List[TypeName] = List(
    integers, floating, specials,
    List(process, ostream, istream
  )).flatten

  val typesKind2: List[TypeName] = List(array)

  val generatedVariableTypes: List[(String, Poly)] = List(
    List("add", "sub", "mul", "mod").map(mkIdFun(_, 3)(num)),
    List("fdiv").map(mkRetFun(_, f64)(num)),
    List("idiv").map(mkRetFun(_, i64)(num)),
    List("neg").map(mkIdFun(_, 2)(num)),
    List("trunc", "round").map(mkRetFun(_, i64)(floating)),
    List("floor", "ceil").map(mkIdFun(_, 2)(floating)),
    num.map(a => num.map(b => f"sys_${a.x}_to_${b.x}" -> Poly(fun(a, b), Nil)))
  ).flatten.flatten ++ List[(String, Poly)](
    "sys_I8_to_Str"  -> Poly(fun(i8,  arr(i8))),
    "sys_I16_to_Str" -> Poly(fun(i16, arr(i8))),
    "sys_I32_to_Str" -> Poly(fun(i32, arr(i8))),
    "sys_I64_to_Str" -> Poly(fun(i64, arr(i8))),
    "sys_F32_to_Str" -> Poly(fun(f32, arr(i8))),
    "sys_F64_to_Str" -> Poly(fun(f64, arr(i8))),
    "sys_lt_I8"  -> Poly(fun(i8,  i8,  bool)),
    "sys_lt_I16" -> Poly(fun(i16, i16, bool)),
    "sys_lt_I32" -> Poly(fun(i32, i32, bool)),
    "sys_lt_I64" -> Poly(fun(i64, i64, bool)),
    "sys_lt_F32" -> Poly(fun(f32, f32, bool)),
    "sys_lt_F64" -> Poly(fun(f64, f64, bool)),
    "sys_arr_get" -> Poly(fun(arr(aa), i32, aa), forall(aa) :: Nil),
    "sys_arr_len" -> Poly(fun(arr(aa), i32), forall(aa) :: Nil)
  )

  val manualVariableTypes: List[(String, Poly)] = List(
    "sys_eq" -> Poly(fun(aa, aa, bool), forall(aa) :: Nil),
    "sys_exit" -> Poly(fun(i32, bottom), forall(bottom) :: Nil),
    "sys_fos_write4" -> Poly(fun(ostream, arr(i8), i32, i32, unit)),
    "sys_fos_write" -> Poly(fun(ostream, arr(i8), unit)),
    "sys_stdin" -> Poly(istream),
    "sys_stdout" -> Poly(ostream),
    "sys_stderr" -> Poly(ostream),
    "append" -> Poly(fun(arr(aa), arr(aa), arr(aa)), forall(aa) :: Nil),
    "quote" -> Poly(fun(aa, term), forall(aa) :: Nil)
  )

  val variables: Map[String, Any] = Map(
    "sys_stdin" -> System.in,
    "sys_stdout" -> System.out,
    "sys_stderr" -> System.err,
    "true" -> true,
    "false" -> false,
    "Nil" -> Nil
  )

  val functions: Map[String, List[Any] => Any] = Map(
    "sys_I8_to_Str"  ->  { case List(x: Byte  ) => stob(x.toChar.toString) },
    "sys_I16_to_Str" ->  { case List(x: Short ) => stob(x.toString) },
    "sys_I32_to_Str" ->  { case List(x: Int   ) => stob(x.toString) },
    "sys_I64_to_Str" ->  { case List(x: Long  ) => stob(x.toString) },
    "sys_F32_to_Str" ->  { case List(x: Float ) => stob(x.toString) },
    "sys_F64_to_Str" ->  { case List(x: Double) => stob(x.toString) },
    "sys_I16_to_I8" ->  { case List(x: Short ) => x.toByte },
    "sys_I32_to_I8" ->  { case List(x: Int   ) => x.toByte },
    "sys_I64_to_I8" ->  { case List(x: Long  ) => x.toByte },
    "sys_F32_to_I8" ->  { case List(x: Float ) => x.toByte },
    "sys_F64_to_I8" ->  { case List(x: Double) => x.toByte },
    "sys_I8_to_I16" ->  { case List(x: Byte  ) => x.toShort },
    "sys_I32_to_I16" -> { case List(x: Int   ) => x.toShort },
    "sys_I64_to_I16" -> { case List(x: Long  ) => x.toShort },
    "sys_F32_to_I16" -> { case List(x: Float ) => x.toShort },
    "sys_F64_to_I16" -> { case List(x: Double) => x.toShort },
    "sys_I8_to_I32" ->  { case List(x: Byte  ) => x.toInt },
    "sys_I16_to_I32" -> { case List(x: Short ) => x.toInt },
    "sys_I64_to_I32" -> { case List(x: Long  ) => x.toInt },
    "sys_F32_to_I32" -> { case List(x: Float ) => x.toInt },
    "sys_F64_to_I32" -> { case List(x: Double) => x.toInt },
    "sys_I8_to_I64" ->  { case List(x: Byte  ) => x.toLong },
    "sys_I16_to_I64" -> { case List(x: Short ) => x.toLong },
    "sys_I32_to_I64" -> { case List(x: Int   ) => x.toLong },
    "sys_F32_to_I64" -> { case List(x: Float ) => x.toLong },
    "sys_F64_to_I64" -> { case List(x: Double) => x.toLong },
    "sys_I8_to_F32" ->  { case List(x: Byte  ) => x.toFloat },
    "sys_I16_to_F32" -> { case List(x: Short ) => x.toFloat },
    "sys_I32_to_F32" -> { case List(x: Int   ) => x.toFloat },
    "sys_I64_to_F32" -> { case List(x: Long  ) => x.toFloat },
    "sys_F64_to_F32" -> { case List(x: Double) => x.toFloat },
    "sys_I8_to_F64" ->  { case List(x: Byte  ) => x.toDouble },
    "sys_I16_to_F64" -> { case List(x: Short ) => x.toDouble },
    "sys_I32_to_F64" -> { case List(x: Int   ) => x.toDouble },
    "sys_I64_to_F64" -> { case List(x: Long  ) => x.toDouble },
    "sys_F32_to_F64" -> { case List(x: Float ) => x.toDouble },
    "sys_add_I8" ->  { case List(x: Byte  , y: Byte  ) => x + y },
    "sys_add_I16" -> { case List(x: Short , y: Short ) => x + y },
    "sys_add_I32" -> { case List(x: Int   , y: Int   ) => x + y },
    "sys_add_I64" -> { case List(x: Long  , y: Long  ) => x + y },
    "sys_add_F32" -> { case List(x: Float , y: Float ) => x + y },
    "sys_add_F64" -> { case List(x: Double, y: Double) => x + y },
    "sys_add_I8" ->  { case List(x: Byte  , y: Byte  ) => x + y },
    "sys_add_I16" -> { case List(x: Short , y: Short ) => x + y },
    "sys_add_I32" -> { case List(x: Int   , y: Int   ) => x + y },
    "sys_add_I64" -> { case List(x: Long  , y: Long  ) => x + y },
    "sys_add_F32" -> { case List(x: Float , y: Float ) => x + y },
    "sys_add_F64" -> { case List(x: Double, y: Double) => x + y },
    "sys_sub_I8" ->  { case List(x: Byte  , y: Byte  ) => x - y },
    "sys_sub_I16" -> { case List(x: Short , y: Short ) => x - y },
    "sys_sub_I32" -> { case List(x: Int   , y: Int   ) => x - y },
    "sys_sub_I64" -> { case List(x: Long  , y: Long  ) => x - y },
    "sys_sub_F32" -> { case List(x: Float , y: Float ) => x - y },
    "sys_sub_F64" -> { case List(x: Double, y: Double) => x - y },
    "sys_mul_I8" ->  { case List(x: Byte  , y: Byte  ) => x * y },
    "sys_mul_I16" -> { case List(x: Short , y: Short ) => x * y },
    "sys_mul_I32" -> { case List(x: Int   , y: Int   ) => x * y },
    "sys_mul_I64" -> { case List(x: Long  , y: Long  ) => x * y },
    "sys_mul_F32" -> { case List(x: Float , y: Float ) => x * y },
    "sys_mul_F64" -> { case List(x: Double, y: Double) => x * y },
    "sys_mod_I8" ->  { case List(x: Byte  , y: Byte  ) => x % y },
    "sys_mod_I16" -> { case List(x: Short , y: Short ) => x % y },
    "sys_mod_I32" -> { case List(x: Int   , y: Int   ) => x % y },
    "sys_mod_I64" -> { case List(x: Long  , y: Long  ) => x % y },
    "sys_mod_F32" -> { case List(x: Float , y: Float ) => x % y },
    "sys_mod_F64" -> { case List(x: Double, y: Double) => x % y },
    "sys_fdiv_I8" ->  { case List(x: Byte  , y: Byte  ) => x.toDouble / y },
    "sys_fdiv_I16" -> { case List(x: Short , y: Short ) => x.toDouble / y },
    "sys_fdiv_I32" -> { case List(x: Int   , y: Int   ) => x.toDouble / y },
    "sys_fdiv_I64" -> { case List(x: Long  , y: Long  ) => x.toDouble / y },
    "sys_fdiv_F32" -> { case List(x: Float , y: Float ) => x.toDouble / y },
    "sys_fdiv_F64" -> { case List(x: Double, y: Double) => x / y },
    "sys_idiv_I8" ->  { case List(x: Byte  , y: Byte  ) => x / y },
    "sys_idiv_I16" -> { case List(x: Short , y: Short ) => x / y },
    "sys_idiv_I32" -> { case List(x: Int   , y: Int   ) => x / y },
    "sys_idiv_I64" -> { case List(x: Long  , y: Long  ) => x / y },
    "sys_idiv_F32" -> { case List(x: Float , y: Float ) => x.toLong / y },
    "sys_idiv_F64" -> { case List(x: Double, y: Double) => x.toLong / y },
    "sys_neg_I8" ->  { case List(x: Byte  ) => -x },
    "sys_neg_I16" -> { case List(x: Short ) => -x },
    "sys_neg_I32" -> { case List(x: Int   ) => -x },
    "sys_neg_I64" -> { case List(x: Long  ) => -x },
    "sys_neg_F32" -> { case List(x: Float ) => -x },
    "sys_neg_F64" -> { case List(x: Double) => -x },
    "sys_trunc_F32" -> { case List(x: Float)  => x.floor.toLong },
    "sys_trunc_F64" -> { case List(x: Double) => x.floor.toLong },
    "sys_floor_F32" -> { case List(x: Float)  => x.floor },
    "sys_floor_F64" -> { case List(x: Double) => x.floor },
    "sys_ceil_F32" -> { case List(x: Float)  => x.ceil },
    "sys_ceil_F64" -> { case List(x: Double) => x.ceil },
    "sys_round_F32" -> { case List(x: Float)  => x.round.toLong },
    "sys_round_F64" -> { case List(x: Double) => x.round },
    "sys_eq_Any" ->    { case List(x: Any    , y: Any    ) => x == y },
    "sys_lt_I8" ->     { case List(x: Byte   , y: Byte   ) => x < y },
    "sys_lt_I16" ->    { case List(x: Short  , y: Short  ) => x < y },
    "sys_lt_I32" ->    { case List(x: Int    , y: Int    ) => x < y },
    "sys_lt_I64" ->    { case List(x: Long   , y: Long   ) => x < y },
    "sys_lt_F32" ->    { case List(x: Float  , y: Float  ) => x < y },
    "sys_lt_F64" ->    { case List(x: Double , y: Double ) => x < y },
    "sys_arr_new_I8" ->   { case List(n: Int) => new Array[Byte]   (n) },
    "sys_arr_new_I16" ->  { case List(n: Int) => new Array[Short]  (n) },
    "sys_arr_new_I32" ->  { case List(n: Int) => new Array[Int]    (n) },
    "sys_arr_new_I64" ->  { case List(n: Int) => new Array[Long]   (n) },
    "sys_arr_new_F32" ->  { case List(n: Int) => new Array[Float]  (n) },
    "sys_arr_new_F64" ->  { case List(n: Int) => new Array[Double] (n) },
    "sys_arr_new_Bool" -> { case List(n: Int) => new Array[Boolean](n) },
    "sys_arr_new_Any" ->  { case List(n: Int) => new Array[Any]    (n) },
    "sys_arr_cpy_I8" ->   { case List(a: Array[Byte]   , b: Array[Byte]   , i: Int, n: Int) => a.copyToArray(b, i, n) },
    "sys_arr_cpy_I16" ->  { case List(a: Array[Short]  , b: Array[Short]  , i: Int, n: Int) => a.copyToArray(b, i, n) },
    "sys_arr_cpy_I32" ->  { case List(a: Array[Int]    , b: Array[Int]    , i: Int, n: Int) => a.copyToArray(b, i, n) },
    "sys_arr_cpy_I64" ->  { case List(a: Array[Long]   , b: Array[Long]   , i: Int, n: Int) => a.copyToArray(b, i, n) },
    "sys_arr_cpy_F32" ->  { case List(a: Array[Float]  , b: Array[Float]  , i: Int, n: Int) => a.copyToArray(b, i, n) },
    "sys_arr_cpy_F64" ->  { case List(a: Array[Double] , b: Array[Double] , i: Int, n: Int) => a.copyToArray(b, i, n) },
    "sys_arr_cpy_Bool" -> { case List(a: Array[Boolean], b: Array[Boolean], i: Int, n: Int) => a.copyToArray(b, i, n) },
    "sys_arr_cpy_Any" ->  { case List(a: Array[Any]    , b: Array[Any]    , i: Int, n: Int) => a.copyToArray(b, i, n) },
    "sys_arr_set_I8" ->   { case List(a: Array[Byte]   , i: Int, x: Byte   ) => a(i) = x },
    "sys_arr_set_I16" ->  { case List(a: Array[Short]  , i: Int, x: Short  ) => a(i) = x },
    "sys_arr_set_I32" ->  { case List(a: Array[Int]    , i: Int, x: Int    ) => a(i) = x },
    "sys_arr_set_I64" ->  { case List(a: Array[Long]   , i: Int, x: Long   ) => a(i) = x },
    "sys_arr_set_F32" ->  { case List(a: Array[Float]  , i: Int, x: Float  ) => a(i) = x },
    "sys_arr_set_F64" ->  { case List(a: Array[Double] , i: Int, x: Double ) => a(i) = x },
    "sys_arr_set_Bool" -> { case List(a: Array[Boolean], i: Int, x: Boolean) => a(i) = x },
    "sys_arr_set_Any" ->  { case List(a: Array[Any]    , i: Int, x: Any    ) => a(i) = x },
    "sys_arr_get"  -> { case List(a: Array[_], i: Int) => a(i) },
    "sys_arr_len"  -> { case List(a: Array[_]) => a.length },
    "sys_getenv" -> { case List(a: Array[Byte]) => withStr(a)(System.getenv) },
    "sys_getprop" -> { case List(a: Array[Byte]) => withStr(a)(System.getProperty) },
    "sys_exit" -> { case List(x: Int) => System.exit(x) },
    "sys_nano_time" -> { case List() => System.nanoTime() },
    "sys_mili_time" -> { case List() => System.currentTimeMillis() },
    "sys_fos_flush" -> { case List(x: OutputStream) => x.flush() },
    "sys_fos_write4" -> { case List(x: OutputStream, a: Array[Byte], i: Int, n: Int) => x.write(a, i, n) },
    "sys_fos_write" -> { case List(x: OutputStream, a: Array[Byte]) => x.write(a) },
    "sys_fos_close" -> { case List(x: OutputStream) => x.close() },
    "sys_fis_read" ->  { case List(x: InputStream, a: Array[Byte], i: Int, n: Int) => x.read(a, i, n) },
    "sys_fis_close" -> { case List(x: InputStream) => x.close() },
    "sys_fis_skip" ->  { case List(x: InputStream, n: Long) => x.skip(n) },
    "sys_fis_avail" -> { case List(x: InputStream) => x.available() },
    "sys_fis_new" -> { case List(a: Array[Byte]) => new FileInputStream(btos(a)) },
    "sys_fos_new" -> { case List(a: Array[Byte]) => new FileOutputStream(btos(a)) },
    "sys_exec" -> { case List(x: Array[Byte], y: Array[Array[Byte]]) => Runtime.getRuntime.exec(btos(x), y.map(btos)) },
    "sys_proc_wait" -> { case List(x: Process) => x.waitFor() },
    "sys_proc_err" -> { case List(x: Process) => x.getErrorStream },
    "sys_proc_fos" -> { case List(x: Process) => x.getOutputStream },
    "sys_proc_fis" -> { case List(x: Process) => x.getInputStream },
    "sys_proc_code" -> { case List(x: Process) => x.exitValue }
  )
}
