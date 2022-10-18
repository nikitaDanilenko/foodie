package services.reference

sealed abstract class DBError(errorMessage: String) extends Throwable(errorMessage)

object DBError {
  case object ReferenceMapNotFound   extends DBError("No reference map with the given id for the given user found")
  case object ReferenceEntryNotFound extends DBError("No reference map entry with the given id found")
}
