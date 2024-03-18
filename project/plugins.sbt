addSbtPlugin("com.typesafe.play"    % "sbt-plugin"        % "2.9.2")
addSbtPlugin("com.github.tototoshi" % "sbt-slick-codegen" % "2.2.0")
addSbtPlugin("nl.gn0s1s"            % "sbt-dotenv"        % "3.0.0")

libraryDependencies += "org.postgresql" % "postgresql" % "42.7.2"

ThisBuild / libraryDependencySchemes += "org.scala-lang.modules" %% "scala-xml" % VersionScheme.Always
