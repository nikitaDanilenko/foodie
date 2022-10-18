package services.reference

import services.{NutrientCode, ReferenceMapId}

case class ReferenceEntryCreation(
    referenceMapId: ReferenceMapId,
    nutrientCode: NutrientCode,
    amount: BigDecimal
)

object ReferenceEntryCreation {

  def create(referenceNutrientCreation: ReferenceEntryCreation): ReferenceEntry =
    ReferenceEntry(
      nutrientCode = referenceNutrientCreation.nutrientCode,
      amount = referenceNutrientCreation.amount
    )

}
