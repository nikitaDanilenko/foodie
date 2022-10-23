package services.nutrient

import cats.Applicative
import cats.data.OptionT
import cats.syntax.contravariantSemigroupal._
import cats.syntax.traverse._
import db.generated.Tables
import io.scalaland.chimney.dsl.TransformerOps
import play.api.db.slick.{DatabaseConfigProvider, HasDatabaseConfigProvider}
import services.recipe.Ingredient
import services.{DBError, FoodId, MeasureId}
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import spire.implicits._
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._

import javax.inject.Inject
import scala.concurrent.{ExecutionContext, Future}

trait NutrientService {

  def nutrientsOfFood(
      foodId: FoodId,
      measureId: MeasureId,
      factor: BigDecimal
  ): Future[NutrientMap]

  def nutrientsOfIngredient(
      ingredient: Ingredient
  ): Future[NutrientMap]

  def nutrientsOfIngredients(
      ingredients: Seq[Ingredient]
  ): Future[NutrientMap]

  def all: Future[Seq[Nutrient]]
}

object NutrientService {

  trait Companion {

    def nutrientOfFood(
        foodId: FoodId,
        measureId: MeasureId,
        amount: BigDecimal
    )(implicit ec: ExecutionContext): DBIO[NutrientMap]

    def nutrientsOfIngredient(
        ingredient: Ingredient
    )(implicit ec: ExecutionContext): DBIO[NutrientMap]

    def nutrientsOfIngredients(
        ingredients: Seq[Ingredient]
    )(implicit ec: ExecutionContext): DBIO[NutrientMap]

    def conversionFactor(
        foodId: FoodId,
        measureId: MeasureId
    )(implicit ec: ExecutionContext): DBIO[Tables.ConversionFactorRow]

    def all(implicit ec: ExecutionContext): DBIO[Seq[Nutrient]]
  }

  class Live @Inject() (
      override protected val dbConfigProvider: DatabaseConfigProvider,
      companion: Companion
  )(implicit ec: ExecutionContext)
      extends NutrientService
      with HasDatabaseConfigProvider[PostgresProfile] {

    override def nutrientsOfFood(foodId: FoodId, measureId: MeasureId, factor: BigDecimal): Future[NutrientMap] =
      db.run(companion.nutrientOfFood(foodId, measureId, factor))

    override def nutrientsOfIngredient(ingredient: Ingredient): Future[NutrientMap] =
      db.run(companion.nutrientsOfIngredient(ingredient))

    override def nutrientsOfIngredients(ingredients: Seq[Ingredient]): Future[NutrientMap] =
      db.run(companion.nutrientsOfIngredients(ingredients))

    override def all: Future[Seq[Nutrient]] =
      db.run(companion.all)

  }

  object Live extends Companion {

    override def conversionFactor(
        foodId: FoodId,
        measureId: MeasureId
    )(implicit
        ec: ExecutionContext
    ): DBIO[Tables.ConversionFactorRow] =
      OptionT(
        Tables.ConversionFactor
          .filter(cf =>
            cf.foodId === foodId.transformInto[Int] &&
              cf.measureId === measureId.transformInto[Int]
          )
          .result
          .headOption: DBIO[Option[Tables.ConversionFactorRow]]
      )
        .getOrElseF(DBIO.failed(DBError.Nutrient.ConversionFactorNotFound))

    override def nutrientOfFood(
        foodId: FoodId,
        measureId: MeasureId,
        factor: BigDecimal
    )(implicit
        ec: ExecutionContext
    ): DBIO[NutrientMap] =
      for {
        nutrientBase     <- nutrientBaseOf(foodId)
        conversionFactor <- conversionFactor(foodId, measureId)
      } yield factor *: conversionFactor.conversionFactorValue *: nutrientBase

    override def nutrientsOfIngredient(ingredient: Ingredient)(implicit ec: ExecutionContext): DBIO[NutrientMap] =
      nutrientOfFood(
        foodId = ingredient.foodId,
        measureId = ingredient.amountUnit.measureId,
        factor = ingredient.amountUnit.factor
      )

    override def nutrientsOfIngredients(ingredients: Seq[Ingredient])(implicit
        ec: ExecutionContext
    ): DBIO[NutrientMap] =
      ingredients
        .traverse(nutrientsOfIngredient)
        .map(_.qsum)

    override def all(implicit ec: ExecutionContext): DBIO[Seq[Nutrient]] =
      Tables.NutrientName.result
        .map(_.map(_.transformInto[Nutrient]))

    private def getNutrient(
        idOrCode: Int
    )(implicit ec: ExecutionContext): DBIO[Option[Nutrient]] =
      OptionT(
        Tables.NutrientName
          .filter(n => n.nutrientNameId === idOrCode || n.nutrientCode === idOrCode)
          .result
          .headOption: DBIO[Option[Tables.NutrientNameRow]]
      )
        .map(_.transformInto[Nutrient])
        .value

    private def nutrientBaseOf(
        foodId: FoodId
    )(implicit
        ec: ExecutionContext
    ): DBIO[NutrientMap] =
      for {
        nutrientAmounts <-
          Tables.NutrientAmount
            .filter(_.foodId === foodId.transformInto[Int])
            .result
        pairs <-
          nutrientAmounts
            .traverse(n =>
              (
                getNutrient(n.nutrientId),
                Applicative[DBIO].pure(n.nutrientValue)
              ).mapN((n, a) => n.map(_ -> a))
            )
      } yield pairs.flatten.toMap

  }

}
