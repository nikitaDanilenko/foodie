package services.nutrient

import algebra.instances.MapAdditiveMonoid
import services.FoodId
import spire.algebra.{ Field, LeftModule, Ring }
import spire.implicits._
import spire.math.Natural

case class AmountEvaluation(
    amount: BigDecimal,
    encounteredFoodIds: Set[FoodId]
)

object AmountEvaluation {

  def embed(amount: BigDecimal, foodId: FoodId): AmountEvaluation = AmountEvaluation(amount, Set(foodId))

  implicit val amountEvaluationField: Field[AmountEvaluation] = new Field[AmountEvaluation] {
    override def zero: AmountEvaluation = AmountEvaluation(BigDecimal(0), Set.empty)

    override def plus(x: AmountEvaluation, y: AmountEvaluation): AmountEvaluation =
      AmountEvaluation(x.amount + y.amount, x.encounteredFoodIds ++ y.encounteredFoodIds)

    override def div(x: AmountEvaluation, y: AmountEvaluation): AmountEvaluation =
      AmountEvaluation(x.amount / y.amount, x.encounteredFoodIds ++ y.encounteredFoodIds)

    override def one: AmountEvaluation = AmountEvaluation(BigDecimal(1), Set.empty)

    override def times(x: AmountEvaluation, y: AmountEvaluation): AmountEvaluation =
      AmountEvaluation(x.amount * y.amount, x.encounteredFoodIds ++ y.encounteredFoodIds)

    override def negate(x: AmountEvaluation): AmountEvaluation = x.copy(amount = -x.amount)
  }

  implicit val leftModule: LeftModule[Map[Nutrient, AmountEvaluation], BigDecimal] =
    new MapAdditiveMonoid[Nutrient, AmountEvaluation]() with LeftModule[Map[Nutrient, AmountEvaluation], BigDecimal] {
      override def scalar: Ring[BigDecimal] = Ring[BigDecimal]

      override def timesl(r: BigDecimal, v: Map[Nutrient, AmountEvaluation]): Map[Nutrient, AmountEvaluation] =
        v.view.mapValues(a => a.copy(amount = r * a.amount)).toMap

      override def negate(x: Map[Nutrient, AmountEvaluation]): Map[Nutrient, AmountEvaluation] =
        x.view.mapValues(-_).toMap

    }

}
