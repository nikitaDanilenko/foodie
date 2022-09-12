package services.stats

import services.NutrientCode

case class ReferenceNutrientCreation(
    nutrientCode: NutrientCode,
    amount: BigDecimal
)

object ReferenceNutrientCreation {

  def create(referenceNutrientCreation: ReferenceNutrientCreation): ReferenceNutrient =
    ReferenceNutrient(
      nutrientCode = referenceNutrientCreation.nutrientCode,
      amount = referenceNutrientCreation.amount
    )

}
