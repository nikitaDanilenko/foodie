package db.codegen

import cats.effect.{ IO, IOApp, Resource }
import com.typesafe.config.ConfigFactory
import slick.codegen.SourceCodeGenerator
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api.Database
import slick.model.Model

import scala.concurrent.ExecutionContext.Implicits.global

object Codegen extends IOApp.Simple {

  private val outputDir      = "app"
  private val outputPackage  = "db.generated"
  private val excludedTables = Set("flyway_schema_history")

  override val run: IO[Unit] =
    database
      .use(readModel)
      .flatMap(writeSources)

  private lazy val database: Resource[IO, Database] =
    Resource.fromAutoCloseable {
      IO {
        val config = ConfigFactory.load()
        Database.forURL(
          url = config.getString("slick.dbs.default.db.url"),
          user = config.getString("slick.dbs.default.db.user"),
          password = config.getString("slick.dbs.default.db.password"),
          driver = "org.postgresql.Driver"
        )
      }
    }

  private def readModel(db: Database): IO[Model] = {
    val tables = PostgresProfile.defaultTables.map(_.filterNot(table => excludedTables.contains(table.name.name)))
    IO.fromFuture(IO(db.run(PostgresProfile.createModel(Some(tables)).withPinnedSession)))
  }

  private def writeSources(model: Model): IO[Unit] =
    IO {
      new SourceCodeGenerator(model).writeToFile(
        profile = "slick.jdbc.PostgresProfile",
        folder = outputDir,
        pkg = outputPackage
      )
    }

}
