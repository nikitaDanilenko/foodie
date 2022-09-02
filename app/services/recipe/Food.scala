package services.recipe

import db.generated.Tables
import io.scalaland.chimney.Transformer
import services.FoodId
import utils.TransformerUtils.Implicits._
import io.scalaland.chimney.dsl._

case class Food(
    id: FoodId,
    name: String,
    measures: List[Measure]
)

object Food {

  implicit val fromDB: Transformer[(Tables.FoodNameRow, List[Tables.MeasureNameRow]), Food] = {
    case (foodNameRow, measureRows) =>
      Food(
        id = foodNameRow.foodId.transformInto[FoodId],
        name = foodNameRow.foodDescription,
        measures = measureRows.map(_.transformInto[Measure])
      )
  }

}
