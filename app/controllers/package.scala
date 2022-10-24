import errors.ServerError
import io.circe.Json
import play.api.mvc.Result
import play.api.mvc.Results.BadRequest
import io.circe.syntax._
import play.api.http.Writeable

package object controllers {

  def badRequest(serverError: ServerError)(implicit writeable: Writeable[Json]): Result =
    BadRequest(serverError.asJson)

}
