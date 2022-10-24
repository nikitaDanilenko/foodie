package services

sealed abstract class DBError(errorMessage: String) extends Throwable(errorMessage) {}

object DBError {

  object Complex {

    object Food {
      case object NotFound extends DBError("No complex food with the given id found")

      case object RecipeNotFound extends DBError("No recipe with the given id found")
    }

    object Ingredient {
      case object NotFound extends DBError("No complex ingredient with the given id found")

      case object RecipeNotFound extends DBError("No recipe with the given id found")
      case object Cycle          extends DBError("Adding this ingredient introduces a cycle")
    }

  }

  object Meal {
    case object NotFound extends DBError("No meal with the given id for the given user found")

    case object EntryNotFound extends DBError("No meal entry with the given id found")
  }

  object Nutrient {

    case object ConversionFactorNotFound
        extends DBError("No conversion factor for the given food and chosen measure found")

  }

  object Recipe {
    case object NotFound extends DBError("No recipe with the given id for the given user found")

    case object IngredientNotFound extends DBError("No recipe ingredient with the given id found")
  }

  object Reference {
    case object MapNotFound extends DBError("No reference map with the given id for the given user found")

    case object EntryNotFound extends DBError("No reference map entry with the given id found")
  }

  object User {
    case object NotFound extends DBError("No user with the given id found")
  }

}
