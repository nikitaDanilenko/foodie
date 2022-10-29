package errors

sealed trait ErrorContext {
  def message: String
}

object ErrorContext {

  sealed abstract class ServerErrorInstance(override val message: String) extends ErrorContext

  /* No automatic derivation to avoid upcasting issue, since any instance of ErrorContext has a more precise type. */
  implicit class ErrorContextToServerError(val errorContext: ErrorContext) extends AnyVal {
    def asServerError: ServerError = ServerError.fromContext(errorContext)
  }

  object Login {
    case object Failure extends ServerErrorInstance("Invalid combination of user name and password.")
    case object Session extends ServerErrorInstance("The user has been logged out.")
  }

  object Authentication {

    object Token {
      case object Decoding extends ServerErrorInstance("Error decoding JWT: Format or signature is wrong")
      case object Content  extends ServerErrorInstance("Error parsing JWT content: Unexpected format")
      case object Missing  extends ServerErrorInstance("Missing JWT")
    }

  }

  object User {
    case object NotFound extends ServerErrorInstance("No user with the given id found")

    case object Exists extends ServerErrorInstance("A user with the given nickname already exists.")

    case object Confirmation extends ServerErrorInstance("Confirmation token missing or invalid.")

    case object Mismatch extends ServerErrorInstance("Settings do not correspond to requested settings")

    case object PasswordUpdate extends ServerErrorInstance("Password update failed")

    case object InvalidCredentials extends ServerErrorInstance("Invalid combination of nickname and password")
  }

  object Recipe {
    case object NotFound extends ServerErrorInstance("No recipe with the given id found")

    case class Creation(dbMessage: String)
        extends ServerErrorInstance(
          s"Recipe creation failed due to: $dbMessage"
        )

    case class Update(dbMessage: String)
        extends ServerErrorInstance(
          s"Recipe update failed due to: $dbMessage"
        )

    case class General(dbMessage: String)
        extends ServerErrorInstance(
          s"A database operation failed with the message: $dbMessage"
        )

    object Ingredient {

      case class Creation(dbMessage: String)
          extends ServerErrorInstance(
            s"Ingredient creation failed due to: $dbMessage"
          )

      case class Update(dbMessage: String)
          extends ServerErrorInstance(
            s"Recipe ingredient update failed due to: $dbMessage"
          )

      case object NotFound extends ServerErrorInstance("No ingredient with the given id found")

    }

    object ComplexIngredient {

      case class Creation(dbMessage: String)
          extends ServerErrorInstance(
            s"Complex ingredient creation failed due to: $dbMessage"
          )

      case class Update(dbMessage: String)
          extends ServerErrorInstance(
            s"Complex ingredient update failed due to: $dbMessage"
          )

      case object NotFound extends ServerErrorInstance("No complex ingredient with the given id found")
    }

  }

  object ComplexFood {

    case class Creation(dbMessage: String)
        extends ServerErrorInstance(
          s"Complex food creation failed due to: $dbMessage"
        )

    case class Update(dbMessage: String)
        extends ServerErrorInstance(
          s"Complex food update failed due to: $dbMessage"
        )

    case object Reference
        extends ServerErrorInstance(
          s"Referenced recipe not found."
        )

    case class General(dbMessage: String)
        extends ServerErrorInstance(
          s"Request failed due to: $dbMessage"
        )

    case object NotFound extends ServerErrorInstance("No complex food with the given id found")
  }

  object Meal {
    case object NotFound extends ServerErrorInstance("No meal with the given id found")

    case class Creation(dbMessage: String)
        extends ServerErrorInstance(
          s"Meal creation failed due to: $dbMessage"
        )

    case class Update(dbMessage: String)
        extends ServerErrorInstance(
          s"Meal update failed due to: $dbMessage"
        )

    case class General(dbMessage: String)
        extends ServerErrorInstance(
          s"A database operation failed with the message: $dbMessage"
        )

    object Entry {

      case class Creation(dbMessage: String)
          extends ServerErrorInstance(
            s"Entry creation failed due to: $dbMessage"
          )

      case class Update(dbMessage: String)
          extends ServerErrorInstance(
            s"Meal entry update failed due to: $dbMessage"
          )

      case object NotFound extends ServerErrorInstance("No entry with the given id found")

    }

  }

  object ReferenceMap {

    case object NotFound extends ServerErrorInstance("No reference map with the given id found")

    case class Creation(dbMessage: String)
        extends ServerErrorInstance(
          s"Reference map creation failed due to: $dbMessage"
        )

    case class Update(dbMessage: String)
        extends ServerErrorInstance(
          s"Reference map update failed due to: $dbMessage"
        )

    case class General(dbMessage: String)
        extends ServerErrorInstance(
          s"A database operation failed with the message: $dbMessage"
        )

    object Entry {

      case class Creation(dbMessage: String)
          extends ServerErrorInstance(
            s"Reference map entry creation failed due to: $dbMessage"
          )

      case class Update(dbMessage: String)
          extends ServerErrorInstance(
            s"Reference map entry update failed due to: $dbMessage"
          )

      case object NotFound extends ServerErrorInstance("No reference map entry with the given id found")

    }

  }

  object Mail {
    case object SendingFailed extends ServerErrorInstance("Sending of message failed")
  }

}
