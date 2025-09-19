import com.typesafe.config.ConfigFactory

name         := """foodie"""
organization := "io.danilenko"
maintainer   := "nikita.danilenko.is@gmail.com"

version := "0.1"

val circeVersion = "0.14.14"
val slickVersion = "3.6.1"
val jwtVersion   = "11.0.2"

val config = ConfigFactory
  .parseFile(new File("conf/application.conf"))
  .resolve()

lazy val root = (project in file("."))
  .enablePlugins(PlayScala)
  .enablePlugins(CodegenPlugin)
  .enablePlugins(JavaServerAppPackaging)
  .settings(
    scalaVersion := "2.13.16",
    libraryDependencies ++= Seq(
      guice,
      "com.typesafe.slick"    %% "slick"                    % slickVersion,
      "com.typesafe.slick"    %% "slick-hikaricp"           % slickVersion,
      "com.typesafe.slick"    %% "slick-codegen"            % slickVersion,
      "org.postgresql"         % "postgresql"               % "42.7.8",
      "ch.qos.logback"         % "logback-classic"          % "1.5.18",
      "net.logstash.logback"   % "logstash-logback-encoder" % "8.1",
      "io.circe"              %% "circe-core"               % circeVersion,
      "io.circe"              %% "circe-generic"            % circeVersion,
      "io.circe"              %% "circe-parser"             % circeVersion,
      "org.typelevel"         %% "spire"                    % "0.18.0",
      "org.flywaydb"          %% "flyway-play"              % "9.1.0",
      "org.playframework"     %% "play-slick"               % "6.2.0",
      "com.dripower"          %% "play-circe"               % "3014.1",
      "com.davegurnell"       %% "bridges"                  % "0.24.0",
      "com.github.pathikrit"  %% "better-files"             % "3.9.2",
      "com.typesafe"           % "config"                   % "1.4.5",
      "io.scalaland"          %% "chimney"                  % "1.8.2",
      "com.github.jwt-scala"  %% "jwt-core"                 % jwtVersion,
      "com.github.jwt-scala"  %% "jwt-circe"                % jwtVersion,
      "com.github.pureconfig" %% "pureconfig"               % "0.17.9",
      "org.typelevel"         %% "cats-effect"              % "3.6.3",
      "org.typelevel"         %% "cats-core"                % "2.13.0",
      "com.beachape"          %% "enumeratum-circe"         % "1.9.0",
      "org.playframework"     %% "play-mailer"              % "10.1.0",
      "org.playframework"     %% "play-mailer-guice"        % "10.1.0",
      "com.lihaoyi"           %% "pprint"                   % "0.9.3",
      "com.kubukoz"           %% "slick-effect"             % "0.6.1",
      "com.kubukoz"           %% "slick-effect-catsio"      % "0.6.1",
      // Transitive dependency. Override added for proper version.
      "com.fasterxml.jackson.module" %% "jackson-module-scala"      % "2.20.0",
      "org.scalacheck"               %% "scalacheck"                % "1.19.0" % Test,
      "org.typelevel"                %% "cats-laws"                 % "2.13.0" % Test,
      "com.github.alexarchambault"   %% "scalacheck-shapeless_1.15" % "1.3.0"  % Test
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
