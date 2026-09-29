package modules

import org.flywaydb.core.Flyway
import org.flywaydb.core.api.output.MigrateResult
import play.api.{ Configuration, Environment, Logger }

import javax.inject.{ Inject, Singleton }

@Singleton
class Migrations @Inject() (configuration: Configuration, environment: Environment) {

  private val logger = Logger(getClass)

  locally {
    val result  = migrate()
    val message = Option(result.targetSchemaVersion).fold("Database schema is up to date")(version =>
      s"Applied ${result.migrationsExecuted} migration(s), schema version is now $version"
    )
    logger.info(message)
  }

  private def migrate(): MigrateResult = {
    val flyway = Flyway
      .configure(environment.classLoader)
      .dataSource(
        configuration.get[String]("db.default.url"),
        configuration.get[String]("db.default.username"),
        configuration.get[String]("db.default.password")
      )
      .locations(Migrations.location)
      .load()

    flyway.migrate()
  }

}

object Migrations {

  val location: String = "db/migration/default"

}
