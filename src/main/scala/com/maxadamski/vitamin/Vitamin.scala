package com.maxadamski.vitamin

import ASTUtils._
import OpUtils.{getArgs, mkGroup}

import scala.reflect.ClassTag


object Vitamin {

  implicit class Castable[A](val self: A) {
    def as[B](implicit tag: ClassTag[B]): Option[B] = self match {
      case that: B => Some(that)
      case _ => None
    }
  }

  class Env(
    var opGroups: Map[String, OpGroup] = Map(),
    var opNames: Seq[OpName] = Seq(),
  )

  def main(args: Array[String]): Unit = {
    var program: AST = Parser.parseFile("res/main.vc")
    var parser = PrattTools.makeParser(Array[Op]())
    var env = new Env()
    //println(program)

    program = program.map() { it =>
      val res = it match {
        case AST(Tag.Flat, _, _) =>
          parser.parse(it)
        case _ =>
          it
      }

      if (res != it) {
        res match {
          case AST(Tag.Pragma, Node(AST(Tag.Atom, Leaf(name: String), _) +: args), _) =>
            val arguments = args.map(_.data).map { case Node(seq) =>
              seq match {
                case Seq(AST(Tag.Atom, Leaf(key: String), _), value) =>
                  Arg(Some(key), value)
                case Seq(value) =>
                  Arg(None, value)
              }
            }.toArray


            name match {
              case "operatorgroup" =>
                val nil = Some(AST(Tag.Atom, Leaf("nil")))
                val defn = Seq(Param("name"), Param("kind"), Param("gt", nil), Param("lt", nil))
                val args = getArgs(defn, arguments).map(_.data.asInstanceOf[Leaf].data.asInstanceOf[String])
                val gt = if (args(2) != "nil") Some(args(2)) else None
                val lt = if (args(3) != "nil") Some(args(3)) else None
                env.opGroups += args(0) -> mkGroup(args(0), args(1), gt, lt)
              case "operator" =>
                val defn = Seq(Param("group"), Param("name", list = true))
                val args = getArgs(defn, arguments)
                val group = args(0).data.asInstanceOf[Leaf].data.asInstanceOf[String]
                val names = args(1).data.asInstanceOf[Node].data.map { name =>
                  name.data.asInstanceOf[Leaf].data.asInstanceOf[String]
                }
                for (name <- names) {
                  env.opNames :+= OpName(group, name)
                }
              case "operatorcompile" =>
                env.opGroups = OpUtils.updateGroups(env.opGroups)
                val ops = OpUtils.mkOps(env.opNames, env.opGroups)
                parser = PrattTools.makeParser(ops)
              case _ =>
                println(s"unknown pragma $res")
            }

          case _ =>
        }
      }

      res
    }

    println(repr(program, multi = true))

    /*
    val noPragma = nextExcept(it => it.tag == Tag.Pragma)(_)
    val nodes = program.fold[Array[AST]](Array(), foldDFS, nextAll) {
      case (sum, node) if node.tag == Tag.Pragma => sum :+ node
      case (sum, _) => sum
    }
    */
  }

}
