import sbt._

object Dependencies {

  // Renovate's sbt manager resolves these shared version vals.
  private val CirceVersion = "0.14.15"

  private val SlickVersion = "3.6.1"

  private val JwtVersion = "11.0.4"

  private val PostgresqlVersion = "42.7.9"

  private val LogbackClassicVersion = "1.5.32"

  private val LogstashLogbackEncoderVersion = "9.0"

  private val SpireVersion = "0.18.0"

  private val FlywayPlayVersion = "9.1.0"

  private val PlaySlickVersion = "6.2.0"

  private val PlayCirceVersion = "3014.1"

  private val BridgesVersion = "0.24.0"

  private val BetterFilesVersion = "3.9.2"

  private val ConfigVersion = "1.4.8"

  private val ChimneyVersion = "1.10.0"

  private val PureconfigVersion = "0.17.10"

  private val CatsEffectVersion = "3.7.0"

  private val CatsCoreVersion = "2.13.0"

  private val EnumeratumCirceVersion = "1.9.7"

  private val PlayMailerVersion = "10.1.0"

  private val PprintVersion = "0.9.6"

  private val SlickEffectVersion = "0.6.1"

  private val JacksonModuleScalaVersion = "2.21.3"

  private val ScalacheckVersion = "1.19.0"

  private val ScalacheckShapelessVersion = "1.12.1"

  val Slick = "com.typesafe.slick" %% "slick" % SlickVersion

  val SlickHikaricp = "com.typesafe.slick" %% "slick-hikaricp" % SlickVersion

  val SlickCodegen = "com.typesafe.slick" %% "slick-codegen" % SlickVersion

  val Postgresql = "org.postgresql" % "postgresql" % PostgresqlVersion

  val LogbackClassic = "ch.qos.logback" % "logback-classic" % LogbackClassicVersion

  val LogstashLogbackEncoder = "net.logstash.logback" % "logstash-logback-encoder" % LogstashLogbackEncoderVersion

  val CirceCore = "io.circe" %% "circe-core" % CirceVersion

  val CirceGeneric = "io.circe" %% "circe-generic" % CirceVersion

  val CirceParser = "io.circe" %% "circe-parser" % CirceVersion

  val Spire = "org.typelevel" %% "spire" % SpireVersion

  val FlywayPlay = "org.flywaydb" %% "flyway-play" % FlywayPlayVersion

  val PlaySlick = "org.playframework" %% "play-slick" % PlaySlickVersion

  val PlayCirce = "com.dripower" %% "play-circe" % PlayCirceVersion

  val Bridges = "com.davegurnell" %% "bridges" % BridgesVersion

  val BetterFiles = "com.github.pathikrit" %% "better-files" % BetterFilesVersion

  val Config = "com.typesafe" % "config" % ConfigVersion

  val Chimney = "io.scalaland" %% "chimney" % ChimneyVersion

  val JwtCore = "com.github.jwt-scala" %% "jwt-core" % JwtVersion

  val JwtCirce = "com.github.jwt-scala" %% "jwt-circe" % JwtVersion

  val Pureconfig = "com.github.pureconfig" %% "pureconfig" % PureconfigVersion

  val CatsEffect = "org.typelevel" %% "cats-effect" % CatsEffectVersion

  val CatsCore = "org.typelevel" %% "cats-core" % CatsCoreVersion

  val EnumeratumCirce = "com.beachape" %% "enumeratum-circe" % EnumeratumCirceVersion

  val PlayMailer = "org.playframework" %% "play-mailer" % PlayMailerVersion

  val PlayMailerGuice = "org.playframework" %% "play-mailer-guice" % PlayMailerVersion

  val Pprint = "com.lihaoyi" %% "pprint" % PprintVersion

  val SlickEffect = "com.kubukoz" %% "slick-effect" % SlickEffectVersion

  val SlickEffectCatsio = "com.kubukoz" %% "slick-effect-catsio" % SlickEffectVersion

  // Transitive dependency. Override added for proper version.
  val JacksonModuleScala = "com.fasterxml.jackson.module" %% "jackson-module-scala" % JacksonModuleScalaVersion

  val Scalacheck = "org.scalacheck" %% "scalacheck" % ScalacheckVersion % Test

  val CatsLaws = "org.typelevel" %% "cats-laws" % CatsCoreVersion % Test

  val ScalacheckShapeless = "com.github.alexarchambault" %% "scalacheck-shapeless_1.15" % ScalacheckShapelessVersion % Test

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