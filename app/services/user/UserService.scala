package services.user

import cats.data.OptionT
import cats.instances.future._
import db.generated.Tables
import io.scalaland.chimney.dsl._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import security.Hash
import services.{ SessionId, UserId }
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

  def getByIdentifier(string: String): Future[Seq[User]]

  def add(user: User): Future[Boolean]

  def update(userId: UserId, userUpdate: UserUpdate): Future[User]

  def updatePassword(userId: UserId, password: String): Future[Boolean]
  def delete(userId: UserId): Future[Boolean]

  def addSession(userId: UserId): Future[SessionId]

  def deleteSession(userId: UserId, sessionId: SessionId): Future[Boolean]

  def deleteAllSessions(userId: UserId): Future[Boolean]

  def existsSession(userId: UserId, sessionId: SessionId): Future[Boolean]
}

object UserService {

  trait Companion {
    def get(userId: UserId)(implicit executionContext: ExecutionContext): DBIO[Option[User]]
    def getByNickname(nickname: String)(implicit executionContext: ExecutionContext): DBIO[Option[User]]
    def getByIdentifier(string: String)(implicit executionContext: ExecutionContext): DBIO[Seq[User]]
    def add(user: User)(implicit executionContext: ExecutionContext): DBIO[Boolean]
    def update(userId: UserId, userUpdate: UserUpdate)(implicit executionContext: ExecutionContext): DBIO[User]
    def updatePassword(userId: UserId, password: String)(implicit executionContext: ExecutionContext): DBIO[Boolean]
    def delete(userId: UserId)(implicit executionContext: ExecutionContext): DBIO[Boolean]
    def addSession(userId: UserId, sessionId: SessionId)(implicit executionContext: ExecutionContext): DBIO[SessionId]
    def deleteSession(userId: UserId, sessionId: SessionId)(implicit executionContext: ExecutionContext): DBIO[Boolean]
    def deleteAllSessions(userId: UserId)(implicit executionContext: ExecutionContext): DBIO[Boolean]
    def existsSession(userId: UserId, sessionId: SessionId)(implicit executionContext: ExecutionContext): DBIO[Boolean]
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
    override def getByIdentifier(string: String): Future[Seq[User]]    = db.run(companion.getByIdentifier(string))
    override def add(user: User): Future[Boolean]                      = db.run(companion.add(user))

    override def update(userId: UserId, userUpdate: UserUpdate): Future[User] =
      db.run(companion.update(userId, userUpdate))

    override def updatePassword(userId: UserId, password: String): Future[Boolean] =
      db.run(companion.updatePassword(userId, password))

    override def delete(userId: UserId): Future[Boolean] = db.run(companion.delete(userId))

    override def addSession(userId: UserId): Future[SessionId] =
      db.run(companion.addSession(userId, UUID.randomUUID().transformInto[SessionId]))

    override def deleteSession(userId: UserId, sessionId: SessionId): Future[Boolean] =
      db.run(companion.deleteSession(userId, sessionId))

    override def deleteAllSessions(userId: UserId): Future[Boolean] = db.run(companion.deleteAllSessions(userId))

    override def existsSession(userId: UserId, sessionId: SessionId): Future[Boolean] =
      db.run(companion.existsSession(userId, sessionId))

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

    override def getByIdentifier(string: String)(implicit executionContext: ExecutionContext): DBIO[Seq[User]] =
      Tables.User
        .filter(u => u.email === string || u.nickname === string)
        .result
        .map(_.map(_.transformInto[User]))

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

    override def addSession(userId: UserId, sessionId: SessionId)(implicit
        executionContext: ExecutionContext
    ): DBIO[SessionId] =
      (Tables.Session.returning(Tables.Session) += Tables.SessionRow(
        id = sessionId.transformInto[UUID],
        userId = userId.transformInto[UUID]
      )).map(_.id.transformInto[SessionId])

    override def deleteSession(userId: UserId, sessionId: SessionId)(implicit
        executionContext: ExecutionContext
    ): DBIO[Boolean] =
      sessionQuery(userId, sessionId).delete
        .map(_ > 0)

    override def deleteAllSessions(userId: UserId)(implicit executionContext: ExecutionContext): DBIO[Boolean] =
      Tables.Session
        .filter(_.userId === userId.transformInto[UUID])
        .delete
        .map(_ > 0)

    override def existsSession(userId: UserId, sessionId: SessionId)(implicit
        executionContext: ExecutionContext
    ): DBIO[Boolean] =
      sessionQuery(userId, sessionId).exists.result

    private def userQuery(userId: UserId): Query[Tables.User, Tables.UserRow, Seq] =
      Tables.User
        .filter(_.id === userId.transformInto[UUID])

    private def sessionQuery(userId: UserId, sessionId: SessionId): Query[Tables.Session, Tables.SessionRow, Seq] =
      Tables.Session
        .filter(session =>
          session.userId === userId.transformInto[UUID] &&
            session.id === sessionId.transformInto[UUID]
        )

  }

}
