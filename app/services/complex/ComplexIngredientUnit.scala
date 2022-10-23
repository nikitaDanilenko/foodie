package services.complex

import enumeratum.{ Enum, EnumEntry }

sealed trait ComplexIngredientUnit extends EnumEntry

object ComplexIngredientUnit extends Enum[ComplexIngredientUnit] {
  case object G  extends ComplexIngredientUnit
  case object ML extends ComplexIngredientUnit

  override lazy val values: IndexedSeq[ComplexIngredientUnit] = findValues
}
