package services

import cats.data.NonEmptyList
import cats.{ Monad, StackSafeMonad }
import db.{ FoodId, MeasureId, UserId }
import io.scalaland.chimney.dsl._
import org.scalacheck.Gen
import security.Hash
import services.nutrient.Nutrient
import services.recipe._
import services.user.User
import spire.math.Natural
import utils.IdType
import utils.TransformerUtils.Implicits._
import utils.date.{ Date, SimpleDate, Time }

import java.time.LocalDate
import java.util.UUID

object GenUtils {

  object implicits {

    implicit val genMonad: Monad[Gen] = new Monad[Gen] with StackSafeMonad[Gen] {
      override def pure[A](x: A): Gen[A] = Gen.const(x)

      override def flatMap[A, B](fa: Gen[A])(f: A => Gen[B]): Gen[B] = fa.flatMap(f)
    }

  }

  private val recipeService = TestUtil.injector.instanceOf[RecipeService]

  val nonEmptyAsciiString: Gen[String] =
    Gen
      .nonEmptyListOf(Gen.asciiPrintableChar)
      .map(_.mkString)

  val userWithFixedPassword: Gen[User] = for {
    id          <- Gen.uuid.map(_.transformInto[UserId])
    nickname    <- nonEmptyAsciiString
    displayName <- Gen.option(nonEmptyAsciiString)
    email       <- nonEmptyAsciiString
    salt        <- Gen.listOfN(40, Gen.alphaNumChar).map(_.mkString)
  } yield User(
    id = id,
    nickname = nickname,
    displayName = displayName,
    email = email,
    salt = salt,
    hash = Hash.fromPassword("password", salt, Hash.defaultIterations)
  )

  val twoUsersGen: Gen[(User, User)] = for {
    user1 <- userWithFixedPassword
    user2 <- userWithFixedPassword
  } yield (
    user1.copy(nickname = "Test user 1"),
    user2.copy(nickname = "Test user 2")
  )

  def optionalOneOf[A](seq: Seq[A]): Gen[Option[A]] =
    if (seq.isEmpty)
      Gen.const(None)
    else Gen.option(Gen.oneOf(seq))

  def subset[A](collection: Iterable[A]): Gen[List[A]] =
    for {
      size   <- Gen.choose(0, collection.size)
      subset <- Gen.pick(size, collection)
    } yield subset.distinct.toList

  def nonEmptySubset[A](nonEmptyList: NonEmptyList[A]): Gen[NonEmptyList[A]] =
    for {
      size   <- Gen.choose(1, nonEmptyList.size)
      subset <- Gen.pick(size, nonEmptyList.toList)
    } yield NonEmptyList.fromListUnsafe(subset.distinct.toList)

  def listOfAtMost[A](n: Natural, gen: Gen[A]): Gen[List[A]] =
    Gen
      .choose(0, n.intValue)
      .flatMap(Gen.listOfN(_, gen))

  def nonEmptyListOfAtMost[A](n: Natural, gen: Gen[A]): Gen[NonEmptyList[A]] =
    Gen
      .choose(1, n.intValue.max(1))
      .flatMap(Gen.listOfN(_, gen))
      .map(NonEmptyList.fromListUnsafe)

  val timeGen: Gen[Time] = for {
    hour   <- Gen.choose(0, 23)
    minute <- Gen.choose(0, 59)
  } yield Time(
    hour = hour,
    minute = minute
  )

  def dateGen(earliest: Int = -100000, latest: Int = 100000): Gen[Date] =
    Gen
      .choose(earliest, latest)
      .map(c => LocalDate.ofEpochDay(c).transformInto[Date])

  def simpleDateGen(earliest: Int = -100000, latest: Int = 100000): Gen[SimpleDate] =
    for {
      date <- dateGen(earliest, latest)
      time <- Gen.option(timeGen)
    } yield SimpleDate(
      date = date,
      time = time
    )

  lazy val allFoods: Map[FoodId, Food] = DBTestUtil
    .await(recipeService.allFoods)
    .map(food =>
      food.id -> food.copy(
        measures = food.measures
          .filter(measure => measure.id != AmountUnit.hundredGrams)
      )
    )
    .toMap

  lazy val allNutrients: Seq[Nutrient] = DBTestUtil.nutrientTableConstants.allNutrients.values.toSeq
  lazy val allMeasures: Seq[Measure]   = DBTestUtil.await(recipeService.allMeasures)

  lazy val allConversionFactors: Map[(FoodId, MeasureId), BigDecimal] =
    DBTestUtil.generalTableConstants.allConversionFactors

  lazy val foodGen: Gen[Food] =
    Gen.oneOf(allFoods.values)

  lazy val nutrientGen: Gen[Nutrient] =
    Gen.oneOf(allNutrients)

  val smallBigDecimalGen: Gen[BigDecimal] = Gen.choose(BigDecimal(0.001), BigDecimal(1000))

  def taggedId(idType: IdType[UUID]): Gen[idType.Type] =
    Gen.uuid.map(idType.apply)

  def shuffle[A](as: Seq[A]): Gen[Seq[A]] =
    Gen
      .pick(as.length, as)
      .map(_.toSeq)

}
