package services.stats

import services.NutrientCode

case class ReferenceNutrientUpdate(
    nutrientCode: NutrientCode,
    amount: BigDecimal
)

object ReferenceNutrientUpdate {

  def update(
      referenceNutrient: ReferenceNutrient,
      referenceNutrientUpdate: ReferenceNutrientUpdate
  ): ReferenceNutrient =
    referenceNutrient.copy(
      amount = referenceNutrientUpdate.amount
    )

}
