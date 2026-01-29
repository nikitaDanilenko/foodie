import com.typesafe.config.ConfigFactory

name         := """foodie"""
organization := "io.danilenko"
maintainer   := "nikita.danilenko.is@gmail.com"

val config = ConfigFactory
  .parseFile(new File("conf/application.conf"))
  .resolve()

lazy val root = (project in file("."))
  .enablePlugins(PlayScala)
  .enablePlugins(CodegenPlugin)
  .enablePlugins(JavaServerAppPackaging)
  .settings(
    scalaVersion := "2.13.18",
    libraryDependencies ++= Seq(
      guice,
      "com.typesafe.slick"    %% "slick"                    % DependencyVersions.Slick,
      "com.typesafe.slick"    %% "slick-hikaricp"           % DependencyVersions.Slick,
      "com.typesafe.slick"    %% "slick-codegen"            % DependencyVersions.Slick,
      "org.postgresql"         % "postgresql"               % DependencyVersions.Postgresql,
      "ch.qos.logback"         % "logback-classic"          % DependencyVersions.LogbackClassic,
      "net.logstash.logback"   % "logstash-logback-encoder" % DependencyVersions.LogstashLogbackEncoder,
      "io.circe"              %% "circe-core"               % DependencyVersions.Circe,
      "io.circe"              %% "circe-generic"            % DependencyVersions.Circe,
      "io.circe"              %% "circe-parser"             % DependencyVersions.Circe,
      "org.typelevel"         %% "spire"                    % DependencyVersions.Spire,
      "org.flywaydb"          %% "flyway-play"              % DependencyVersions.FlywayPlay,
      "org.playframework"     %% "play-slick"               % DependencyVersions.PlaySlick,
      "com.dripower"          %% "play-circe"               % DependencyVersions.PlayCirce,
      "com.davegurnell"       %% "bridges"                  % DependencyVersions.Bridges,
      "com.github.pathikrit"  %% "better-files"             % DependencyVersions.BetterFiles,
      "com.typesafe"           % "config"                   % DependencyVersions.Config,
      "io.scalaland"          %% "chimney"                  % DependencyVersions.Chimney,
      "com.github.jwt-scala"  %% "jwt-core"                 % DependencyVersions.Jwt,
      "com.github.jwt-scala"  %% "jwt-circe"                % DependencyVersions.Jwt,
      "com.github.pureconfig" %% "pureconfig"               % DependencyVersions.Pureconfig,
      "org.typelevel"         %% "cats-effect"              % DependencyVersions.CatsEffect,
      "org.typelevel"         %% "cats-core"                % DependencyVersions.CatsCore,
      "com.beachape"          %% "enumeratum-circe"         % DependencyVersions.EnumeratumCirce,
      "org.playframework"     %% "play-mailer"              % DependencyVersions.PlayMailer,
      "org.playframework"     %% "play-mailer-guice"        % DependencyVersions.PlayMailer,
      "com.lihaoyi"           %% "pprint"                   % DependencyVersions.Pprint,
      "com.kubukoz"           %% "slick-effect"             % DependencyVersions.SlickEffect,
      "com.kubukoz"           %% "slick-effect-catsio"      % DependencyVersions.SlickEffect,
      // Transitive dependency. Override added for proper version.
      "com.fasterxml.jackson.module" %% "jackson-module-scala"      % DependencyVersions.JacksonModuleScala,
      "org.scalacheck"               %% "scalacheck"                % DependencyVersions.Scalacheck % Test,
      "org.typelevel"                %% "cats-laws"                 % DependencyVersions.CatsCore % Test,
      "com.github.alexarchambault"   %% "scalacheck-shapeless_1.15" % DependencyVersions.ScalacheckShapeless  % Test
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
