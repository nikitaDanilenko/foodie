addSbtPlugin("org.playframework" % "sbt-plugin" % "3.1.0-M9")

addSbtPlugin("nl.gn0s1s" % "sbt-dotenv" % "3.3.0")

addSbtPlugin("org.scalameta" % "sbt-scalafmt" % "2.6.2")

ThisBuild / libraryDependencySchemes += "org.scala-lang.modules" %% "scala-xml" % VersionScheme.Always
