package services.stats

sealed abstract class DBError(errorMessage: String) extends Throwable(errorMessage)

object DBError {

  case object ReferenceNutrientNotFound
      extends DBError("No reference nutrient with the given id for the given user found")

}