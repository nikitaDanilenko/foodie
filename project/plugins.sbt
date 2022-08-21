addSbtPlugin("com.typesafe.play"    % "sbt-plugin"        % "2.8.2")
addSbtPlugin("com.github.tototoshi" % "sbt-slick-codegen" % "1.4.0")
addSbtPlugin("au.com.onegeek"       % "sbt-dotenv"        % "2.1.204")

libraryDependencies += "org.postgresql" % "postgresql" % "42.3.6"
