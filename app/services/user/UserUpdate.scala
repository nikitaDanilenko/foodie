package services.user

case class UserUpdate(
    displayName: Option[String],
    email: String
)

object UserUpdate {

  def update(user: User, userUpdate: UserUpdate): User =
    user.copy(
      displayName = userUpdate.displayName,
      email = userUpdate.email
    )

}
