package utils.date

import io.circe.generic.JsonCodec

@JsonCodec
case class SimpleDate(
    date: Date,
    time: Option[Time]
)
