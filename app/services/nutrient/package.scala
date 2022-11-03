package services

package object nutrient {

  type NutrientMap = Map[Nutrient, AmountEvaluation]

  type ReferenceNutrientMap = Map[Nutrient, BigDecimal]

}
