package modules

import play.api.inject.Binding
import play.api.{ Configuration, Environment }
import services.complex.food.ComplexFoodService
import services.complex.ingredient.ComplexIngredientService
import services.meal.MealService
import services.nutrient.NutrientService
import services.recipe.RecipeService
import services.reference.ReferenceService
import services.stats.StatsService
import services.user.UserService

class ApplicationModule extends play.api.inject.Module {

  override def bindings(environment: Environment, configuration: Configuration): collection.Seq[Binding[_]] = {
    val settings = Seq(
      bind[UserService.Companion].toInstance(UserService.Live),
      bind[UserService].to[UserService.Live],
      bind[RecipeService.Companion].toInstance(RecipeService.Live),
      bind[RecipeService].to[RecipeService.Live],
      bind[ComplexIngredientService.Companion].toInstance(ComplexIngredientService.Live),
      bind[ComplexIngredientService].to[ComplexIngredientService.Live],
      bind[ComplexFoodService.Companion].toInstance(ComplexFoodService.Live),
      bind[ComplexFoodService].to[ComplexFoodService.Live],
      bind[MealService.Companion].toInstance(MealService.Live),
      bind[MealService].to[MealService.Live],
      bind[StatsService.Companion].toInstance(StatsService.Live),
      bind[StatsService].to[StatsService.Live],
      bind[NutrientService.Companion].toInstance(NutrientService.Live),
      bind[NutrientService].to[NutrientService.Live],
      bind[ReferenceService.Companion].toInstance(ReferenceService.Live),
      bind[ReferenceService].to[ReferenceService.Live]
    )
    settings
  }

}
