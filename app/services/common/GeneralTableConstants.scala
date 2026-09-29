package services.common

import db.generated.Tables
import db.{ FoodId, MeasureId }
import io.scalaland.chimney.dsl._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.nutrient.ConstantsConfiguration
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import javax.inject.{ Inject, Singleton }
import scala.concurrent.duration._
import scala.concurrent.{ Await, ExecutionContext, Future }

@Singleton
class GeneralTableConstants @Inject() (
    override protected val dbConfigProvider: DatabaseConfigProvider,
    constantsConfiguration: ConstantsConfiguration,
    // Unused, but the dependency makes Guice apply all migrations before any table is read.
    migrations: modules.Migrations
)(implicit executionContext: ExecutionContext)
    extends HasDatabaseConfigProvider[PostgresProfile] {

  private val timeoutInSeconds: Int = constantsConfiguration.timeoutInSeconds

  val allConversionFactors: Map[(FoodId, MeasureId), BigDecimal] = GeneralTableConstants.computeWith {
    Tables.ConversionFactor.result
      .map {
        _.map(row =>
          (row.foodId.transformInto[FoodId], row.measureId.transformInto[MeasureId]) -> row.conversionFactorValue
        ).toMap
      }
  }(db.run, timeoutInSeconds)

  val allMeasureNames: Seq[Tables.MeasureNameRow] =
    GeneralTableConstants.computeWith {
      Tables.MeasureName.result
    }(db.run, timeoutInSeconds)

  val allNutrientNames: Seq[Tables.NutrientNameRow] =
    GeneralTableConstants.computeWith {
      Tables.NutrientName.result
    }(db.run, timeoutInSeconds)

  val allNutrientAmounts: Seq[Tables.NutrientAmountRow] = GeneralTableConstants.computeWith {
    Tables.NutrientAmount.result
  }(db.run, timeoutInSeconds)

  val allFoodNames: Seq[Tables.FoodNameRow] = GeneralTableConstants.computeWith {
    Tables.FoodName.result
  }(db.run, timeoutInSeconds)

}

object GeneralTableConstants {

  def computeWith[A](action: DBIO[A])(run: DBIO[A] => Future[A], timeoutInSeconds: Int): A =
    Await.result(run(action), timeoutInSeconds.seconds)

}
