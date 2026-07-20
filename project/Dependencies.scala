import sbt._

object Dependencies {

  // Renovate's sbt manager can resolve variables, but not from a nested object.
  // For this reason, we limit the sharing to only those versions that are used multiple times.
  // All singleton occurrences are inlined directly.
  private val CirceVersion = "0.14.16"

  private val SlickVersion = "3.6.1"

  private val JwtVersion = "11.0.4"

  private val CatsCoreVersion = "2.13.0"

  private val PlayMailerVersion = "10.1.0"

  private val SlickEffectVersion = "0.6.1"

  // Dependencies

  val Slick = "com.typesafe.slick" %% "slick" % SlickVersion

  val SlickHikaricp = "com.typesafe.slick" %% "slick-hikaricp" % SlickVersion

  val SlickCodegen = "com.typesafe.slick" %% "slick-codegen" % SlickVersion

  val Postgresql = "org.postgresql" % "postgresql" % "42.7.13"

  val LogbackClassic = "ch.qos.logback" % "logback-classic" % "1.5.38"

  val LogstashLogbackEncoder = "net.logstash.logback" % "logstash-logback-encoder" % "9.0"

  val CirceCore = "io.circe" %% "circe-core" % CirceVersion

  val CirceGeneric = "io.circe" %% "circe-generic" % CirceVersion

  val CirceParser = "io.circe" %% "circe-parser" % CirceVersion

  val Spire = "org.typelevel" %% "spire" % "0.18.0"

  val FlywayPlay = "org.flywaydb" %% "flyway-play" % "9.1.0"

  val PlaySlick = "org.playframework" %% "play-slick" % "6.2.0"

  val PlayCirce = "com.dripower" %% "play-circe" % "3014.1"

  val Bridges = "com.davegurnell" %% "bridges" % "0.24.0"

  val BetterFiles = "com.github.pathikrit" %% "better-files" % "3.9.2"

  val Config = "com.typesafe" % "config" % "1.4.9"

  val Chimney = "io.scalaland" %% "chimney" % "1.11.0"

  val JwtCore = "com.github.jwt-scala" %% "jwt-core" % JwtVersion

  val JwtCirce = "com.github.jwt-scala" %% "jwt-circe" % JwtVersion

  val Pureconfig = "com.github.pureconfig" %% "pureconfig" % "0.17.10"

  val CatsEffect = "org.typelevel" %% "cats-effect" % "3.7-4972921"

  val CatsCore = "org.typelevel" %% "cats-core" % CatsCoreVersion

  val EnumeratumCirce = "com.beachape" %% "enumeratum-circe" % "1.9.8"

  val PlayMailer = "org.playframework" %% "play-mailer" % PlayMailerVersion

  val PlayMailerGuice = "org.playframework" %% "play-mailer-guice" % PlayMailerVersion

  val Pprint = "com.lihaoyi" %% "pprint" % "0.9.6"

  val SlickEffect = "com.kubukoz" %% "slick-effect" % SlickEffectVersion

  val SlickEffectCatsio = "com.kubukoz" %% "slick-effect-catsio" % SlickEffectVersion

  // Transitive dependency. Override added for proper version.
  val JacksonModuleScala = "com.fasterxml.jackson.module" %% "jackson-module-scala" % "2.22.1"

  val Scalacheck = "org.scalacheck" %% "scalacheck" % "1.19.0" % Test

  val CatsLaws = "org.typelevel" %% "cats-laws" % CatsCoreVersion % Test

  val ScalacheckShapeless = "com.github.alexarchambault" %% "scalacheck-shapeless_1.15" % "1.3.0" % Test

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
