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
  def add(user: User): Future[Boolean]

  def update(userId: UserId, userUpdate: UserUpdate): Future[User]

  def delete(userId: UserId): Future[Boolean]
}

object UserService {

  trait Companion {
    def get(userId: UserId)(implicit executionContext: ExecutionContext): DBIO[Option[User]]
    def getByNickname(nickname: String)(implicit executionContext: ExecutionContext): DBIO[Option[User]]
    def add(user: User)(implicit executionContext: ExecutionContext): DBIO[Boolean]

    def update(userId: UserId, userUpdate: UserUpdate)(implicit executionContext: ExecutionContext): DBIO[User]

    def delete(userId: UserId)(implicit executionContext: ExecutionContext): DBIO[Boolean]
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
    override def add(user: User): Future[Boolean]                      = db.run(companion.add(user))

    override def update(userId: UserId, userUpdate: UserUpdate): Future[User] =
      db.run(companion.update(userId, userUpdate))

    override def delete(userId: UserId): Future[Boolean] = db.run(companion.delete(userId))
  }

  object Live extends Companion {

    def get(userId: UserId)(implicit executionContext: ExecutionContext): DBIO[Option[User]] =
      OptionT(
        userQuery(userId).result.headOption: DBIO[Option[Tables.UserRow]]
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

    override def add(user: User)(implicit executionContext: ExecutionContext): DBIO[Boolean] =
      (Tables.User += user.transformInto[Tables.UserRow])
        .map(_ > 0)

    override def update(userId: UserId, userUpdate: UserUpdate)(implicit
        executionContext: ExecutionContext
    ): DBIO[User] = {
      val findAction = OptionT(get(userId))
        .getOrElseF(DBIO.failed(DBError.UserNotFound))

      for {
        user <- findAction
        _ <- userQuery(userId).update(
          UserUpdate
            .update(user, userUpdate)
            .transformInto[Tables.UserRow]
        )
        updatedUser <- findAction
      } yield updatedUser
    }

    override def delete(userId: UserId)(implicit executionContext: ExecutionContext): DBIO[Boolean] =
      userQuery(userId).delete
        .map(_ > 0)

    private def userQuery(userId: UserId): Query[Tables.User, Tables.UserRow, Seq] =
      Tables.User
        .filter(_.id === userId.transformInto[UUID])

  }

}
