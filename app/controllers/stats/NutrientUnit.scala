package controllers.stats

import enumeratum.{ CirceEnum, Enum, EnumEntry }
import io.scalaland.chimney.Transformer

sealed trait NutrientUnit extends EnumEntry

object NutrientUnit extends Enum[NutrientUnit] with CirceEnum[NutrientUnit] {

  case object Kilocalorie extends NutrientUnit {
    override val entryName: String = "kCal"
  }

  case object Kilojoule extends NutrientUnit {
    override val entryName: String = "kJ"
  }

  case object Microgram extends NutrientUnit {
    override val entryName: String = "µg"
  }

  case object Milligram extends NutrientUnit {
    override val entryName: String = "mg"
  }

  case object Gram extends NutrientUnit {
    override val entryName: String = "g"
  }

  case object NiacinEquivalent extends NutrientUnit {
    override val entryName: String = "NE"
  }

  case object IU extends NutrientUnit {
    override val entryName: String = "IU"
  }

  override lazy val values: IndexedSeq[NutrientUnit] = findValues

  implicit val fromDomain: Transformer[services.nutrient.NutrientUnit, NutrientUnit] = {
    case services.nutrient.NutrientUnit.Kilocalorie      => Kilocalorie
    case services.nutrient.NutrientUnit.Kilojoule        => Kilojoule
    case services.nutrient.NutrientUnit.Microgram        => Microgram
    case services.nutrient.NutrientUnit.Milligram        => Milligram
    case services.nutrient.NutrientUnit.Gram             => Gram
    case services.nutrient.NutrientUnit.NiacinEquivalent => NiacinEquivalent
    case services.nutrient.NutrientUnit.IU               => IU
  }

}
