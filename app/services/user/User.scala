package services.user

import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._
import services.UserId

case class User(
    id: UserId,
    nickname: String,
    displayName: String,
    email: String,
    salt: String,
    hash: String
)

object User {

  implicit val toRow: Transformer[User, Tables.UserRow] = user =>
    user
      .into[Tables.UserRow]
      .transform

  implicit val fromRow: Transformer[Tables.UserRow, User] = user =>
    user
      .into[User]
      .transform

}
