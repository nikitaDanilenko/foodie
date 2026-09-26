name         := """foodie"""
organization := "io.danilenko"
maintainer   := "nikita.danilenko.is@gmail.com"

lazy val root = (project in file("."))
  .enablePlugins(PlayScala)
  .enablePlugins(JavaServerAppPackaging)
  .settings(
    scalaVersion := "2.13.18",
    libraryDependencies ++= guice +: Dependencies.all,
    // play-slick 7.0.0-M1 still pins Slick 3.5.2, which Slick's own pvp scheme deems incompatible with 3.6.x.
    libraryDependencySchemes ++= Seq(
      "com.typesafe.slick" %% "slick"          % VersionScheme.EarlySemVer,
      "com.typesafe.slick" %% "slick-hikaricp" % VersionScheme.EarlySemVer
    )
  )

scalacOptions ++= Seq(
  "-Ymacro-annotations"
)

lazy val elmGenerate = Command.command("elmGenerate") { state =>
  "runMain elm.Bridge" :: state
}

// Replacement for the former sbt-slick-codegen plugin, which has no sbt 2 build.
lazy val slickCodegen = Command.command("slickCodegen") { state =>
  "runMain db.codegen.Codegen" :: state
}

commands ++= Seq(elmGenerate, slickCodegen)

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
