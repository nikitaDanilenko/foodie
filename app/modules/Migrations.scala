package modules

import org.flywaydb.core.Flyway
import org.flywaydb.core.api.output.MigrateResult
import play.api.{ Configuration, Environment }

import javax.inject.{ Inject, Singleton }

@Singleton
class Migrations @Inject() (configuration: Configuration, environment: Environment) {

  locally {
    val result = migrate()
    println(s"Migration result: $result")
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
