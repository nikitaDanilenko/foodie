package services.user

sealed abstract class DBError(errorMessage: String) extends Throwable(errorMessage)

object DBError {
  case object UserNotFound extends DBError("No user with the given id found")
}
