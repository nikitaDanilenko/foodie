package services.nutrient

import enumeratum.{ EnumEntry, Enum }

sealed trait NutrientUnit extends EnumEntry

object NutrientUnit extends Enum[NutrientUnit] {

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

}
