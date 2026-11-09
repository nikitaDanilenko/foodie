package services.nutrient

import cats.data.OptionT
import cats.syntax.traverse._
import db.generated.Tables
import db.{ FoodId, MeasureId }
import io.scalaland.chimney.dsl._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.DBError
import services.common.GeneralTableConstants
import services.common.Transactionally.syntax._
import services.recipe.{ AmountUnit, Ingredient }
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import spire.implicits._
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._

import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

class Live @Inject() (
    override protected val dbConfigProvider: DatabaseConfigProvider,
    companion: NutrientService.Companion
) extends NutrientService
    with HasDatabaseConfigProvider[PostgresProfile] {

  override def all: Future[Seq[Nutrient]] =
    db.runTransactionally(companion.all)

}

object Live {

  class Companion @Inject() (
      nutrientTableConstants: NutrientTableConstants,
      generalTableConstants: GeneralTableConstants
  ) extends NutrientService.Companion {

    override def conversionFactor(
        foodId: FoodId,
        measureId: MeasureId
    )(implicit
        ec: ExecutionContext
    ): DBIO[BigDecimal] =
      conversionFactorNoEffect(foodId, measureId)
        .fold(DBIO.failed(DBError.Nutrient.ConversionFactorNotFound): DBIO[BigDecimal])(DBIO.successful)

    private def conversionFactorNoEffect(
        foodId: FoodId,
        measureId: MeasureId
    ): Option[BigDecimal] = generalTableConstants.allConversionFactors
      .get((foodId, measureId))
      .orElse {
        val specialized = hundredGrams(foodId.transformInto[Int])
        Option.when(measureId.transformInto[Int] == specialized.measureId)(specialized.conversionFactorValue)
      }

    override def conversionFactors(
        conversionFactorKeys: Seq[NutrientService.ConversionFactorKey]
    )(implicit ec: ExecutionContext): DBIO[Map[NutrientService.ConversionFactorKey, BigDecimal]] =
      OptionT
        .fromOption[DBIO](conversionFactorsOf(conversionFactorKeys))
        .getOrElseF(DBIO.failed(DBError.Nutrient.ConversionFactorNotFound))

    override def nutrientsOfFood(
        foodId: FoodId,
        measureId: Option[MeasureId],
        factor: BigDecimal
    )(implicit
        ec: ExecutionContext
    ): DBIO[NutrientMap] =
      for {
        conversionFactor <-
          measureId
            .fold(DBIO.successful(BigDecimal(1)): DBIO[BigDecimal])(
              conversionFactor(foodId, _)
            )
      } yield factor *: conversionFactor *: nutrientBaseOf(foodId)

    private def nutrientsOfFoodNoEffect(
        foodId: FoodId,
        measureId: Option[MeasureId],
        factor: BigDecimal
    ): Option[NutrientMap] =
      measureId
        .fold(Option(BigDecimal(1)))(conversionFactorNoEffect(foodId, _))
        .map { conversionFactor =>
          factor *: conversionFactor *: nutrientBaseOf(foodId)
        }

    private def conversionFactorsOf(
        conversionFactorKeys: Seq[NutrientService.ConversionFactorKey]
    ): Option[Map[NutrientService.ConversionFactorKey, BigDecimal]] =
      conversionFactorKeys.distinct
        .traverse { key =>
          key.measureId.fold(Option(key -> BigDecimal(1))) { measureId =>
            generalTableConstants.allConversionFactors
              .get((key.foodId, measureId))
              .map(key -> _)
          }
        }
        .map(_.toMap)

    override def nutrientsOfIngredients(ingredients: Seq[Ingredient])(implicit
        ec: ExecutionContext
    ): DBIO[NutrientMap] =
      OptionT
        .fromOption[DBIO] {
          ingredients
            .traverse { ingredient =>
              nutrientsOfFoodNoEffect(
                foodId = ingredient.foodId,
                measureId = ingredient.amountUnit.measureId,
                factor = ingredient.amountUnit.factor
              )
            }
            .map(_.qsum)
        }
        .getOrElseF(DBIO.failed(DBError.Nutrient.ConversionFactorNotFound))

    override val all: DBIO[Seq[Nutrient]] =
      DBIO.successful(nutrientTableConstants.allNutrients.values.toSeq)

    private def nutrientBaseOf(
        foodId: FoodId
    ): NutrientMap =
      nutrientTableConstants.allNutrientMaps
        .getOrElse(foodId, Map.empty)

    private def hundredGrams(foodId: Int): Tables.ConversionFactorRow =
      Tables.ConversionFactorRow(
        foodId = foodId,
        measureId = AmountUnit.hundredGrams.transformInto[Int],
        conversionFactorValue = BigDecimal(1),
        convFactorDateOfEntry = java.sql.Date.valueOf("2022-11-01")
      )

  }

}
