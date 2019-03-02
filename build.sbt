name := "vitamin"
version := "0.1.0"
scalaVersion := "2.11.12"
mainClass := Some("com.maxadamski.vitamin.Vitamin")
//enablePlugins(ScalaNativePlugin)
libraryDependencies += "org.scalactic" %% "scalactic" % "3.0.5"
libraryDependencies += "org.scalatest" %% "scalatest" % "3.0.5" % "test"
assemblyJarName in assembly := "vcc.jar"
