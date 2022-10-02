package services.user

import cats.data.OptionT
import cats.instances.future._
import db.generated.Tables
import io.scalaland.chimney.dsl._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import security.Hash
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

  def getByEmail(email: String): Future[Option[User]]

  def getByNicknameOrEmail(string: String)(implicit executionContext: ExecutionContext): Future[Option[User]] =
    OptionT(getByNickname(string))
      .orElse(OptionT(getByEmail(string)))
      .value

  def add(user: User): Future[Boolean]

  def update(userId: UserId, userUpdate: UserUpdate): Future[User]

  def updatePassword(userId: UserId, password: String): Future[Boolean]
  def delete(userId: UserId): Future[Boolean]
}

object UserService {

  trait Companion {
    def get(userId: UserId)(implicit executionContext: ExecutionContext): DBIO[Option[User]]
    def getByNickname(nickname: String)(implicit executionContext: ExecutionContext): DBIO[Option[User]]
    def getByEmail(email: String)(implicit executionContext: ExecutionContext): DBIO[Option[User]]
    def add(user: User)(implicit executionContext: ExecutionContext): DBIO[Boolean]

    def update(userId: UserId, userUpdate: UserUpdate)(implicit executionContext: ExecutionContext): DBIO[User]
    def updatePassword(userId: UserId, password: String)(implicit executionContext: ExecutionContext): DBIO[Boolean]

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
    override def getByEmail(email: String): Future[Option[User]]       = db.run(companion.getByEmail(email))
    override def add(user: User): Future[Boolean]                      = db.run(companion.add(user))

    override def update(userId: UserId, userUpdate: UserUpdate): Future[User] =
      db.run(companion.update(userId, userUpdate))

    override def updatePassword(userId: UserId, password: String): Future[Boolean] =
      db.run(companion.updatePassword(userId, password))

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

    override def getByEmail(email: String)(implicit executionContext: ExecutionContext): DBIO[Option[User]] =
      OptionT(
        Tables.User
          .filter(_.email === email)
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

    override def updatePassword(userId: UserId, password: String)(implicit
        executionContext: ExecutionContext
    ): DBIO[Boolean] = {
      val transformer = for {
        user <- OptionT(get(userId))
        newHash = Hash.fromPassword(
          password,
          user.salt,
          Hash.defaultIterations
        )
        result <- OptionT.liftF(
          userQuery(userId)
            .map(_.hash)
            .update(newHash)
            .map(_ > 0): DBIO[Boolean]
        )
      } yield result

      transformer.getOrElseF(DBIO.failed(DBError.UserNotFound))
    }

    override def delete(userId: UserId)(implicit executionContext: ExecutionContext): DBIO[Boolean] =
      userQuery(userId).delete
        .map(_ > 0)

    private def userQuery(userId: UserId): Query[Tables.User, Tables.UserRow, Seq] =
      Tables.User
        .filter(_.id === userId.transformInto[UUID])

  }

}
