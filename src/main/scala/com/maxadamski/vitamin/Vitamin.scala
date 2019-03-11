package com.maxadamski.vitamin

import collection.mutable.{ArrayBuffer, Map => MutableMap}
import System.err.{println => eprintln}
import System.exit
import java.io.{File, FileInputStream}
import java.nio.file.{Files, Paths}

import com.maxadamski.vitamin.ast.{Atom, Term, Tree}
import com.maxadamski.vitamin.runtime.Core.{DynamicIL, SyntaxError}
import parser2._
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

  def bench[U](n: Int)(f: => U): (Double, U) = {
    var sum: Long = 0
    var res: Option[U] = None
    for (i <- 1 to n) {
      val t = System.nanoTime()
      res = Some(f)
      sum += System.nanoTime() - t
    }
    sum / n * 1e-9 -> res.get
  }

  def benchAndPrint[U](text: String, n: Int = 1)(f: => U): U = {
    val (dt, res) = bench(1)(f)
    println(f"$text took $dt%.7fs")
    res
  }

  def main(args: Array[String]): Unit = {
    var args2 = args.toList
    if (args2.isEmpty)
      args2 = "res/tests/demo.vc" :: Nil
    val arguments = parseArgs(args2)
    verifyArgs(arguments)

    val env = new Env()
    env.parser.opGroups = Map()
    env.parser.updateParser()

    val functions = Map[String, List[Any] => Any](
      "eval" -> { case List(env: Env, x: Core.DynamicIL.Form) => Core.eval(env)(x) },
      "Term" -> {
        case List(x: List[Tree]) => Term(x)
      },
      "Atom" -> {
        case List(x: String) => Atom(x)
      },
      "cons" -> {
        //case List(x: Tree, Nil) => x cons Term(Nil)
        case List(x: Tree, y: Tree) => x cons y
        case List(x: Any, y: List[Any]) => x :: y
      },
      "append" -> {
        case List(x: Array[_], y: Array[_]) => x ++ y
        case List(Term(x), Term(y)) => Term(x ++ y)
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

    args2 foreach { file =>
      println(s"-- [$file] ------")
      env.file = file

      val t0 = System.nanoTime()

      val bytes = Files.readAllBytes(Paths.get(file))
      val phase1 = benchAndPrint("-- phase 1 (lexer) ") { new Lexer().tokenize(bytes, lexVitaminC) }
      val phase2 = benchAndPrint("-- phase 2 (parser)") { new parser1.Parser(phase1).parseProg() }
      //println(f"-- parsed\n$parsed")
      val phase3 = benchAndPrint("-- phase 3 (expand)") { Core.expand(env, toplevel = true)(phase2) }
      println(f"-- expanded")
      println(phase3)
      val phase4 = benchAndPrint("-- phase 4 (verify)") { Core.transform(env.extend())(phase3)._1 }

      println("-- running program")

      val t1 = System.nanoTime()
      Core.eval(env)(phase4)

      val dt1 = (System.nanoTime() - t1) * 1e-9
      val dt0 = (System.nanoTime() - t0) * 1e-9

      println()
      println(f"-- exited with status code 0")
      println(f"-- run time $dt1%.7fs")
      println(f"-- all time $dt0%.7fs")
    }
  }
}
