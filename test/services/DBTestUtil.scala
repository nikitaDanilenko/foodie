package services

import cats.data.EitherT
import db.generated.Tables
import errors.ServerError
import org.scalacheck.Prop
import services.common.GeneralTableConstants
import services.nutrient.NutrientTableConstants
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._

import scala.concurrent.duration._
import scala.concurrent.{ Await, ExecutionContext, Future }

object DBTestUtil {

  val defaultAwaitTimeout: Duration = 2.minutes

  val generalTableConstants: GeneralTableConstants   = TestUtil.injector.instanceOf[GeneralTableConstants]
  val nutrientTableConstants: NutrientTableConstants = TestUtil.injector.instanceOf[NutrientTableConstants]

  def clearDb(): Unit =
    await(
      dbRun(
        /* The current structure links everything to users at the
             root level, which is why it is sufficient to delete all
             users to also clear all non-CNF tables.
         */
        Tables.User.delete
      )
    )

  def dbRun[A](action: DBIO[A]): Future[A] =
    TestUtil.databaseConfigProvider
      .get[PostgresProfile]
      .db
      .run(action)

  def await[A](future: Future[A], timeout: Duration = defaultAwaitTimeout): A =
    Await.result(
      awaitable = future,
      atMost = timeout
    )

  def awaitProp(
      transformer: EitherT[Future, ServerError, Prop]
  )(implicit executionContext: ExecutionContext): Prop =
    DBTestUtil.await(
      transformer.fold(
        error => {
          pprint.log(error.message)
          Prop.exception
        },
        identity
      )
    )

}
