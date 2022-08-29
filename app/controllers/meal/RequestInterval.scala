package controllers.meal

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

import utils.date.Date

@JsonCodec
case class RequestInterval(
    from: Option[Date],
    to: Option[Date]
)

object RequestInterval {

  implicit val toDomain: Transformer[RequestInterval, services.meal.RequestInterval] =
    Transformer
      .define[RequestInterval, services.meal.RequestInterval]
      .buildTransformer

}
