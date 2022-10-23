package services.complex.food

import enumeratum.{ Enum, EnumEntry }

sealed trait ComplexFoodUnit extends EnumEntry

object ComplexFoodUnit extends Enum[ComplexFoodUnit] {
  case object G  extends ComplexFoodUnit
  case object ML extends ComplexFoodUnit

  override lazy val values: IndexedSeq[ComplexFoodUnit] = findValues
}
