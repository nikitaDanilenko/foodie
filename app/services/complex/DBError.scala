package services.complex

sealed abstract class DBError(errorMessage: String) extends Throwable(errorMessage)

object DBError {
  case object ComplexIngredientNotFound extends DBError("No complex ingredient with the given id found")
  case object RecipeNotFound            extends DBError("No recipe with the given id found")
}
