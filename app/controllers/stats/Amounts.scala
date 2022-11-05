package controllers.stats

import io.circe.generic.JsonCodec

@JsonCodec
case class Amounts(
    values: Option[Values],
    numberOfIngredients: Int,
    numberOfDefinedValues: Int
)
