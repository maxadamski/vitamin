package com.maxadamski.vitamin

import collection.mutable.{ArrayBuffer, Map => MutableMap}
import System.err.{println => eprintln}
import System.exit
import java.io.{File, FileInputStream}
import java.nio.file.{Files, Paths}

import com.maxadamski.vitamin.ast.{Atom, Term, Tree}
import com.maxadamski.vitamin.runtime.Core.SyntaxError
import parser._
import runtime._
import ast.Term._
import TypeSystem._
import jdk.nashorn.internal.parser.Lexer.LexerToken
import lexer.{Lexer, Token => LexerToken}
import lexer.Lexer.lexVitaminC

object Vitamin {
  case class Arguments(
    files: List[String]
  )

  def usageShort: String =
    s"vc [-h|-H] FILE..."

  def usageLong: String =
    s"""
       | NAME
       |    vc - execute VitaminC code
       |
       | USAGE
       |    vc [-h|-H] FILE...
       |
       | DESCRIPTION
       |    -h, --help
       |        print usage
       |
       |    -H, --HELP
       |        print this help
       |
       |    -d, --debug LEVEL
       |        print the program at the specified compilation LEVEL
       |
       | EXAMPLE
       |    vc stdlib.md main.vc
       |
       | NOTES
       |    FILEs are evaluated in the order they're given
       |    (in fact the ASTs in FILEs are concatenated)
     """.stripMargin

  def parseArgs(input: List[String]): Arguments = {
    var args = input
    var files = List[String]()

    while (args.nonEmpty) {
      val head = args.head
      head match {
        case "-h" | "--help" =>
          println(s"usage: $usageShort")
          exit(0)
        case "-H" | "--manual" =>
          println(usageLong)
          exit(0)
        case _ =>
          files :+= head
          args = args.drop(1)
      }
    }

    Arguments(
      files = files
    )
  }

  def verifyArgs(args: Arguments): Unit = {
    args.files foreach verifyFile

    if (args.files.isEmpty) {
      printError(s"no files given")
      exit(1)
    }
  }

  def printError(str: String): Unit = {
    eprintln(s"[error] $str")
  }

  def printWarn(str: String): Unit = {
    println(s"[warn] $str")
  }

  def verifyFile(it: String): Unit = {
    val path = Paths.get(it)
    val file = path.toFile
    if (!file.exists) {
      printError(s"file '$it' doesn't exist")
      exit(1)
    }
    if (file.isDirectory) {
      printError(s"file '$it' is a directory, which is not allowed yet")
      exit(1)
    }
    if (!it.endsWith(".vc")) {
      printWarn(s"extension of file '$it' is not '.vc'")
    }
  }

  def bench[U](n: Int)(f: => U): Double = {
    var sum: Long = 0
    for (i <- 0 to n) {
      val t = System.nanoTime()
      f
      sum += System.nanoTime() - t
    }
    sum / n * 1e-9
  }

  def main(args: Array[String]): Unit = {
    var args2 = args.toList
    if (args2.isEmpty)
      args2 = "res/tests/lexer.vc" :: Nil
    val arguments = parseArgs(args2)
    verifyArgs(arguments)

    val env = new Env()
    env.parser.opGroups = Map()
    env.parser.updateParser()

    env.variables = MutableMap[String, Any](
      "true" -> true,
      "false" -> false,
      "Nil" -> Nil
    )

    val functions = Map[String, List[Any] => Any](
      "eval" -> { case List(env: Env, x: Core.DynamicIL.Form) => Core.eval(env)(x) },
      "," -> { args => args },
      "List" -> { args => args },
      "Term" -> {
        case List(x: List[Tree]) => Term(x)
      },
      "Atom" -> {
        case List(x: String) => Atom(x)
      },
      "atom?" -> {
        case List(Atom(_)) => true
        case List(_) => false
      },
      "term?" -> {
        case List(Term(_)) => true
        case List(_) => false
      },
      "head" -> {
        case List(Term(head :: _)) => head
        case List(head :: _) => head
      },
      "tail" -> {
        case List(Term(_ :: tail)) => Term(tail)
        case List(_ :: tail) => tail
      },
      "cons" -> {
        //case List(x: Tree, Nil) => x cons Term(Nil)
        case List(x: Tree, y: Tree) => x cons y
        case List(x: Any, y: List[Any]) => x :: y
        case other => throw new Exception(f"expected (T, List(T)), got $other")
      },
      "append" -> {
        case List(Term(x), Term(y)) => Term(x ++ y)
        case x: List[List[_]] => x.reduce(_ ++ _)
        case other => throw new Exception(f"expected (List(T), List(T)), got $other")
      },
      "typeof" -> { case List(x) =>
        x match {
          case _: Boolean => "Bool"
          case _: Int => "Int"
          case _: Float => "Float"
          case _: String => "String"
          case _: Atom => "Atom"
          case _: Term => "Term"
          case _ => "Any"
        }
      }
    )

    functions.foreach(env.variables.+=)
    ScalaBuiltins.generatedVariableTypes.foreach(env.typeOf.+=)
    ScalaBuiltins.manualVariableTypes.foreach(env.typeOf.+=)
    ScalaBuiltins.functions.foreach(env.variables.+=)
    ScalaBuiltins.variables.foreach(env.variables.+=)
    ScalaBuiltins.typesKind1.foreach(t => env.kindOf(t.x) = 1)
    ScalaBuiltins.typesKind2.foreach(t => env.kindOf(t.x) = 2)
    env.kindOf("->") = 3

    import ScalaBuiltins.{tn, tc, fun}
    val eq_a = sat(tc(tn("Eq"), tn("'a")))
    val all_a = forall(tn("'a"))

    args2 foreach { file =>
      println(s"-- [$file] ------")
      env.file = file

      //var parsed = Parser.parseFile(file)
      val bytes = Files.readAllBytes(Paths.get(file))
      var lexed: Array[lexer.Token] = Array()
      val dt = bench(10) {
        val lexer = new Lexer()
        lexed = lexer.tokenize(bytes, lexVitaminC)
      }
      println(lexed.mkString("\n"))
      println(f"lexed in $dt%.8f s")
      val parsed = Term(Nil)

      try {
        val expanded = Core.expand(env, toplevel = true)(parsed)
        println("-- expanded ------")
        println(expanded)

        println("-- running  ------")
        val (form, formType) = Core.transform(env.extend())(expanded)
        Core.eval(env)(form)
        //println("exit (0)")
      } catch {
        case SyntaxError(message) =>
          eprintln("-- syntax error --")
          eprintln(message)
          exit(1)
      }
    }
  }
}
