package services.reference

import services.nutrient.ReferenceNutrientMap

case class ReferenceTree(
    referenceMap: ReferenceMap,
    nutrientMap: ReferenceNutrientMap
)
