package services.complex.food

sealed abstract class DBError(errorMessage: String) extends Throwable(errorMessage)

object DBError {
  case object ComplexFoodNotFound extends DBError("No complex food with the given id found")
  case object RecipeNotFound      extends DBError("No recipe with the given id found")
}
