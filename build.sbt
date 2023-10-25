import com.typesafe.config.ConfigFactory

name         := """foodie"""
organization := "io.danilenko"
maintainer   := "nikita.danilenko.is@gmail.com"

version := "0.1"

val circeVersion = "0.14.6"
val slickVersion = "3.4.1"
val jwtVersion   = "9.4.4"

val config = ConfigFactory
  .parseFile(new File("conf/application.conf"))
  .resolve()

lazy val root = (project in file("."))
  .enablePlugins(PlayScala)
  .enablePlugins(CodegenPlugin)
  .enablePlugins(JavaServerAppPackaging)
  .settings(
    scalaVersion := "2.13.12",
    libraryDependencies ++= Seq(
      guice,
      "com.typesafe.slick"    %% "slick"               % slickVersion,
      "com.typesafe.slick"    %% "slick-hikaricp"      % slickVersion,
      "com.typesafe.slick"    %% "slick-codegen"       % slickVersion,
      "org.postgresql"         % "postgresql"          % "42.6.0",
      "ch.qos.logback"         % "logback-classic"     % "1.4.8",
      "io.circe"              %% "circe-core"          % circeVersion,
      "io.circe"              %% "circe-generic"       % circeVersion,
      "io.circe"              %% "circe-parser"        % circeVersion,
      "org.typelevel"         %% "spire"               % "0.18.0",
      "org.flywaydb"          %% "flyway-play"         % "7.41.0",
      "com.typesafe.play"     %% "play-slick"          % "5.1.0",
      "com.dripower"          %% "play-circe"          % "2814.4",
      "com.davegurnell"       %% "bridges"             % "0.24.0",
      "com.github.pathikrit"  %% "better-files"        % "3.9.2",
      "com.typesafe"           % "config"              % "1.4.3",
      "io.scalaland"          %% "chimney"             % "0.8.0",
      "com.github.jwt-scala"  %% "jwt-core"            % jwtVersion,
      "com.github.jwt-scala"  %% "jwt-circe"           % jwtVersion,
      "com.github.pureconfig" %% "pureconfig"          % "0.17.4",
      "org.typelevel"         %% "cats-effect"         % "3.4.9",
      "org.typelevel"         %% "cats-effect"         % "3.5.2",
      "org.typelevel"         %% "cats-core"           % "2.10.0",
      "com.beachape"          %% "enumeratum-circe"    % "1.7.3",
      "com.typesafe.play"     %% "play-mailer"         % "8.0.1",
      "com.typesafe.play"     %% "play-mailer-guice"   % "8.0.1",
      "com.lihaoyi"           %% "pprint"              % "0.8.1",
      "com.kubukoz"           %% "slick-effect"        % "0.5.0",
      "com.kubukoz"           %% "slick-effect-catsio" % "0.5.0",
      // Transitive dependency. Override added for proper version.
      "com.fasterxml.jackson.module" %% "jackson-module-scala"      % "2.15.3",
      "org.scalacheck"               %% "scalacheck"                % "1.17.0" % Test,
      "org.typelevel"                %% "cats-laws"                 % "2.10.0" % Test,
      "com.github.alexarchambault"   %% "scalacheck-shapeless_1.15" % "1.3.0"  % Test
    ),
    dependencyOverrides ++= Seq(
      "com.google.inject" % "guice" % "5.1.0"
    ),
    slickCodegenDatabaseUrl      := config.getString("slick.dbs.default.db.url"),
    slickCodegenDatabaseUser     := config.getString("slick.dbs.default.db.user"),
    slickCodegenDatabasePassword := config.getString("slick.dbs.default.db.password"),
    slickCodegenDriver           := slick.jdbc.PostgresProfile,
    slickCodegenJdbcDriver       := "org.postgresql.Driver",
    slickCodegenOutputPackage    := "db.generated",
    slickCodegenExcludedTables   := Seq("flyway_schema_history"),
    slickCodegenOutputDir        := baseDirectory.value / "app"
  )

scalacOptions ++= Seq(
  "-Ymacro-annotations"
)

lazy val elmGenerate = Command.command("elmGenerate") { state =>
  "runMain elm.Bridge" :: state
}

commands += elmGenerate

Docker / maintainer    := "nikita.danilenko.is@gmail.com"
Docker / packageName   := "foodie"
Docker / version       := sys.env.getOrElse("BUILD_NUMBER", "0")
Docker / daemonUserUid := None
Docker / daemonUser    := "daemon"
dockerBaseImage        := "adoptopenjdk/openjdk11:latest"
dockerUpdateLatest     := true

// Patches and workarounds

// Docker has known issues with Play's PID file. The below command disables Play's PID file.
// cf. https://www.playframework.com/documentation/2.8.x/Deploying#Play-PID-Configuration
// The setting is a possible duplicate of the same setting in the application.conf.
Universal / javaOptions ++= Seq(
  "-Dpidfile.path=/dev/null"
)
