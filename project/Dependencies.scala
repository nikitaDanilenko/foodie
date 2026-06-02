import sbt._

object Dependencies {

  // Renovate's sbt manager resolves version vals from the nested Versions object.
  private object Versions {

    val Circe = "0.14.15"

    val Slick = "3.6.1"

    val Jwt = "11.0.4"

    val Postgresql = "42.7.9"

    val LogbackClassic = "1.5.32"

    val LogstashLogbackEncoder = "9.0"

    val Spire = "0.18.0"

    val FlywayPlay = "9.1.0"

    val PlaySlick = "6.2.0"

    val PlayCirce = "3014.1"

    val Bridges = "0.24.0"

    val BetterFiles = "3.9.2"

    val Config = "1.4.8"

    val Chimney = "1.10.0"

    val Pureconfig = "0.17.10"

    val CatsEffect = "3.7.0"

    val CatsCore = "2.13.0"

    val EnumeratumCirce = "1.9.7"

    val PlayMailer = "10.1.0"

    val Pprint = "0.9.6"

    val SlickEffect = "0.6.1"

    val JacksonModuleScala = "2.21.3"

    val Scalacheck = "1.19.0"

    val ScalacheckShapeless = "1.3.0"

  }

  val Slick = "com.typesafe.slick" %% "slick" % Versions.Slick

  val SlickHikaricp = "com.typesafe.slick" %% "slick-hikaricp" % Versions.Slick

  val SlickCodegen = "com.typesafe.slick" %% "slick-codegen" % Versions.Slick

  val Postgresql = "org.postgresql" % "postgresql" % Versions.Postgresql

  val LogbackClassic = "ch.qos.logback" % "logback-classic" % Versions.LogbackClassic

  val LogstashLogbackEncoder = "net.logstash.logback" % "logstash-logback-encoder" % Versions.LogstashLogbackEncoder

  val CirceCore = "io.circe" %% "circe-core" % Versions.Circe

  val CirceGeneric = "io.circe" %% "circe-generic" % Versions.Circe

  val CirceParser = "io.circe" %% "circe-parser" % Versions.Circe

  val Spire = "org.typelevel" %% "spire" % Versions.Spire

  val FlywayPlay = "org.flywaydb" %% "flyway-play" % Versions.FlywayPlay

  val PlaySlick = "org.playframework" %% "play-slick" % Versions.PlaySlick

  val PlayCirce = "com.dripower" %% "play-circe" % Versions.PlayCirce

  val Bridges = "com.davegurnell" %% "bridges" % Versions.Bridges

  val BetterFiles = "com.github.pathikrit" %% "better-files" % Versions.BetterFiles

  val Config = "com.typesafe" % "config" % Versions.Config

  val Chimney = "io.scalaland" %% "chimney" % Versions.Chimney

  val JwtCore = "com.github.jwt-scala" %% "jwt-core" % Versions.Jwt

  val JwtCirce = "com.github.jwt-scala" %% "jwt-circe" % Versions.Jwt

  val Pureconfig = "com.github.pureconfig" %% "pureconfig" % Versions.Pureconfig

  val CatsEffect = "org.typelevel" %% "cats-effect" % Versions.CatsEffect

  val CatsCore = "org.typelevel" %% "cats-core" % Versions.CatsCore

  val EnumeratumCirce = "com.beachape" %% "enumeratum-circe" % Versions.EnumeratumCirce

  val PlayMailer = "org.playframework" %% "play-mailer" % Versions.PlayMailer

  val PlayMailerGuice = "org.playframework" %% "play-mailer-guice" % Versions.PlayMailer

  val Pprint = "com.lihaoyi" %% "pprint" % Versions.Pprint

  val SlickEffect = "com.kubukoz" %% "slick-effect" % Versions.SlickEffect

  val SlickEffectCatsio = "com.kubukoz" %% "slick-effect-catsio" % Versions.SlickEffect

  // Transitive dependency. Override added for proper version.
  val JacksonModuleScala = "com.fasterxml.jackson.module" %% "jackson-module-scala" % Versions.JacksonModuleScala

  val Scalacheck = "org.scalacheck" %% "scalacheck" % Versions.Scalacheck % Test

  val CatsLaws = "org.typelevel" %% "cats-laws" % Versions.CatsCore % Test

  val ScalacheckShapeless = "com.github.alexarchambault" %% "scalacheck-shapeless_1.15" % Versions.ScalacheckShapeless % Test

  val all: Seq[ModuleID] = Seq(
    Slick,
    SlickHikaricp,
    SlickCodegen,
    Postgresql,
    LogbackClassic,
    LogstashLogbackEncoder,
    CirceCore,
    CirceGeneric,
    CirceParser,
    Spire,
    FlywayPlay,
    PlaySlick,
    PlayCirce,
    Bridges,
    BetterFiles,
    Config,
    Chimney,
    JwtCore,
    JwtCirce,
    Pureconfig,
    CatsEffect,
    CatsCore,
    EnumeratumCirce,
    PlayMailer,
    PlayMailerGuice,
    Pprint,
    SlickEffect,
    SlickEffectCatsio,
    JacksonModuleScala,
    Scalacheck,
    CatsLaws,
    ScalacheckShapeless
  )

}