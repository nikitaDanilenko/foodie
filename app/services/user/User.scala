package services.user

import db.generated.Tables
import db.UserId
import io.scalaland.chimney.Transformer
import utils.TransformerUtils.Implicits._

case class User(
    id: UserId,
    nickname: String,
    displayName: Option[String],
    email: String,
    salt: String,
    hash: String
)

object User {

  implicit val toRow: Transformer[User, Tables.UserRow] =
    Transformer
      .define[User, Tables.UserRow]
      .buildTransformer

  implicit val fromRow: Transformer[Tables.UserRow, User] =
    Transformer
      .define[Tables.UserRow, User]
      .buildTransformer

}
