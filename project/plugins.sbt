addSbtPlugin("org.playframework"    % "sbt-plugin"        % "3.0.5")
addSbtPlugin("com.github.tototoshi" % "sbt-slick-codegen" % "2.2.0")
addSbtPlugin("nl.gn0s1s"            % "sbt-dotenv"        % "3.0.0")

libraryDependencies += "org.postgresql" % "postgresql" % "42.7.3"

ThisBuild / libraryDependencySchemes += "org.scala-lang.modules" %% "scala-xml" % VersionScheme.Always
