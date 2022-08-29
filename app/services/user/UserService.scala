package services.user

import cats.data.OptionT
import db.generated.Tables
import io.scalaland.chimney.dsl._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.UserId
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

trait UserService {
  def get(userId: UserId): Future[Option[User]]
  def getByNickname(nickname: String): Future[Option[User]]
}

object UserService {

  trait Companion {
    def get(userId: UserId)(implicit executionContext: ExecutionContext): DBIO[Option[User]]
    def getByNickname(nickname: String)(implicit executionContext: ExecutionContext): DBIO[Option[User]]
  }

  class Live @Inject() (
      override protected val dbConfigProvider: DatabaseConfigProvider,
      companion: Companion
  )(implicit
      executionContext: ExecutionContext
  ) extends UserService
      with HasDatabaseConfigProvider[PostgresProfile] {
    override def get(userId: UserId): Future[Option[User]]             = db.run(companion.get(userId))
    override def getByNickname(nickname: String): Future[Option[User]] = db.run(companion.getByNickname(nickname))
  }

  object Live extends Companion {

    def get(userId: UserId)(implicit executionContext: ExecutionContext): DBIO[Option[User]] =
      OptionT(
        Tables.User
          .filter(_.id === userId.transformInto[UUID])
          .result
          .headOption: DBIO[Option[Tables.UserRow]]
      )
        .map(_.transformInto[User])
        .value

    override def getByNickname(nickname: String)(implicit executionContext: ExecutionContext): DBIO[Option[User]] =
      OptionT(
        Tables.User
          .filter(_.nickname === nickname)
          .result
          .headOption: DBIO[Option[Tables.UserRow]]
      )
        .map(_.transformInto[User])
        .value

  }

}
