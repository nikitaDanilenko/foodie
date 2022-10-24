package controllers.complex

import enumeratum.{ CirceEnum, Enum, EnumEntry }
import io.scalaland.chimney.Transformer

sealed trait ComplexFoodUnit extends EnumEntry

object ComplexFoodUnit extends Enum[ComplexFoodUnit] with CirceEnum[ComplexFoodUnit] {
  case object G  extends ComplexFoodUnit
  case object ML extends ComplexFoodUnit

  override lazy val values: IndexedSeq[ComplexFoodUnit] = findValues

  implicit val toInternal: Transformer[ComplexFoodUnit, services.complex.food.ComplexFoodUnit] = {
    case G  => services.complex.food.ComplexFoodUnit.G
    case ML => services.complex.food.ComplexFoodUnit.ML
  }

  implicit val fromInternal: Transformer[services.complex.food.ComplexFoodUnit, ComplexFoodUnit] = {
    case services.complex.food.ComplexFoodUnit.G  => G
    case services.complex.food.ComplexFoodUnit.ML => ML
  }

}
