package modules

import play.api.inject.{ Binding, Module }
import play.api.{ Configuration, Environment }

class MigrationsModule extends Module {

  override def bindings(environment: Environment, configuration: Configuration): collection.Seq[Binding[_]] =
    Seq(bind[Migrations].toSelf.eagerly())

}
