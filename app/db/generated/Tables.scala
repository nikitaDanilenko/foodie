package db.generated
// AUTO-GENERATED Slick data model
/** Stand-alone Slick data model for immediate use */
object Tables extends {
  val profile = slick.jdbc.PostgresProfile
} with Tables

/** Slick data model trait for extension, choice of backend or usage in the cake pattern. (Make sure to initialize this late.) */
trait Tables {
  val profile: slick.jdbc.JdbcProfile
  import profile.api._
  import slick.model.ForeignKeyAction
  // NOTE: GetResult mappers for plain SQL are only generated for tables where Slick knows how to map the types of all columns.
  import slick.jdbc.{GetResult => GR}

  /** DDL for all tables. Call .create to execute. */
  lazy val schema: profile.SchemaDescription = Array(ConversionFactor.schema, FoodGroup.schema, FoodName.schema, FoodSource.schema, Meal.schema, MealEntry.schema, MeasureName.schema, NutrientAmount.schema, NutrientName.schema, NutrientSource.schema, Recipe.schema, RecipeIngredient.schema, ReferenceEntry.schema, ReferenceMap.schema, RefuseAmount.schema, RefuseName.schema, Session.schema, User.schema, YieldAmount.schema, YieldName.schema).reduceLeft(_ ++ _)
  @deprecated("Use .schema instead of .ddl", "3.0")
  def ddl = schema

  /** Entity class storing rows of table ConversionFactor
   *  @param foodId Database column food_id SqlType(int4)
   *  @param measureId Database column measure_id SqlType(int4)
   *  @param conversionFactorValue Database column conversion_factor_value SqlType(numeric)
   *  @param convFactorDateOfEntry Database column conv_factor_date_of_entry SqlType(date) */
  case class ConversionFactorRow(foodId: Int, measureId: Int, conversionFactorValue: scala.math.BigDecimal, convFactorDateOfEntry: java.sql.Date)
  /** GetResult implicit for fetching ConversionFactorRow objects using plain SQL queries */
  implicit def GetResultConversionFactorRow(implicit e0: GR[Int], e1: GR[scala.math.BigDecimal], e2: GR[java.sql.Date]): GR[ConversionFactorRow] = GR{
    prs => import prs._
    ConversionFactorRow.tupled((<<[Int], <<[Int], <<[scala.math.BigDecimal], <<[java.sql.Date]))
  }
  /** Table description of table conversion_factor. Objects of this class serve as prototypes for rows in queries. */
  class ConversionFactor(_tableTag: Tag) extends profile.api.Table[ConversionFactorRow](_tableTag, Some("cnf"), "conversion_factor") {
    def * = (foodId, measureId, conversionFactorValue, convFactorDateOfEntry) <> (ConversionFactorRow.tupled, ConversionFactorRow.unapply)
    /** Maps whole row to an option. Useful for outer joins. */
    def ? = ((Rep.Some(foodId), Rep.Some(measureId), Rep.Some(conversionFactorValue), Rep.Some(convFactorDateOfEntry))).shaped.<>({r=>import r._; _1.map(_=> ConversionFactorRow.tupled((_1.get, _2.get, _3.get, _4.get)))}, (_:Any) =>  throw new Exception("Inserting into ? projection not supported."))

    /** Database column food_id SqlType(int4) */
    val foodId: Rep[Int] = column[Int]("food_id")
    /** Database column measure_id SqlType(int4) */
    val measureId: Rep[Int] = column[Int]("measure_id")
    /** Database column conversion_factor_value SqlType(numeric) */
    val conversionFactorValue: Rep[scala.math.BigDecimal] = column[scala.math.BigDecimal]("conversion_factor_value")
    /** Database column conv_factor_date_of_entry SqlType(date) */
    val convFactorDateOfEntry: Rep[java.sql.Date] = column[java.sql.Date]("conv_factor_date_of_entry")

    /** Primary key of ConversionFactor (database name conversion_factor_pk) */
    val pk = primaryKey("conversion_factor_pk", (foodId, measureId))
  }
  /** Collection-like TableQuery object for table ConversionFactor */
  lazy val ConversionFactor = new TableQuery(tag => new ConversionFactor(tag))

  /** Entity class storing rows of table FoodGroup
   *  @param foodGroupId Database column food_group_id SqlType(int4), PrimaryKey
   *  @param foodGroupCode Database column food_group_code SqlType(text), Default(None)
   *  @param foodGroupName Database column food_group_name SqlType(text), Default(None)
   *  @param foodGroupNameF Database column food_group_name_f SqlType(text), Default(None) */
  case class FoodGroupRow(foodGroupId: Int, foodGroupCode: Option[String] = None, foodGroupName: Option[String] = None, foodGroupNameF: Option[String] = None)
  /** GetResult implicit for fetching FoodGroupRow objects using plain SQL queries */
  implicit def GetResultFoodGroupRow(implicit e0: GR[Int], e1: GR[Option[String]]): GR[FoodGroupRow] = GR{
    prs => import prs._
    FoodGroupRow.tupled((<<[Int], <<?[String], <<?[String], <<?[String]))
  }
  /** Table description of table food_group. Objects of this class serve as prototypes for rows in queries. */
  class FoodGroup(_tableTag: Tag) extends profile.api.Table[FoodGroupRow](_tableTag, Some("cnf"), "food_group") {
    def * = (foodGroupId, foodGroupCode, foodGroupName, foodGroupNameF) <> (FoodGroupRow.tupled, FoodGroupRow.unapply)
    /** Maps whole row to an option. Useful for outer joins. */
    def ? = ((Rep.Some(foodGroupId), foodGroupCode, foodGroupName, foodGroupNameF)).shaped.<>({r=>import r._; _1.map(_=> FoodGroupRow.tupled((_1.get, _2, _3, _4)))}, (_:Any) =>  throw new Exception("Inserting into ? projection not supported."))

    /** Database column food_group_id SqlType(int4), PrimaryKey */
    val foodGroupId: Rep[Int] = column[Int]("food_group_id", O.PrimaryKey)
    /** Database column food_group_code SqlType(text), Default(None) */
    val foodGroupCode: Rep[Option[String]] = column[Option[String]]("food_group_code", O.Default(None))
    /** Database column food_group_name SqlType(text), Default(None) */
    val foodGroupName: Rep[Option[String]] = column[Option[String]]("food_group_name", O.Default(None))
    /** Database column food_group_name_f SqlType(text), Default(None) */
    val foodGroupNameF: Rep[Option[String]] = column[Option[String]]("food_group_name_f", O.Default(None))
  }
  /** Collection-like TableQuery object for table FoodGroup */
  lazy val FoodGroup = new TableQuery(tag => new FoodGroup(tag))

  /** Entity class storing rows of table FoodName
   *  @param foodId Database column food_id SqlType(int4)
   *  @param foodCode Database column food_code SqlType(int4)
   *  @param foodGroupId Database column food_group_id SqlType(int4)
   *  @param foodSourceId Database column food_source_id SqlType(int4)
   *  @param foodDescription Database column food_description SqlType(text)
   *  @param foodDescriptionF Database column food_description_f SqlType(text)
   *  @param foodDateOfEntry Database column food_date_of_entry SqlType(date)
   *  @param foodDateOfPublication Database column food_date_of_publication SqlType(date), Default(None)
   *  @param countryCode Database column country_code SqlType(int4), Default(None)
   *  @param scientificName Database column scientific_name SqlType(text), Default(None) */
  case class FoodNameRow(foodId: Int, foodCode: Int, foodGroupId: Int, foodSourceId: Int, foodDescription: String, foodDescriptionF: String, foodDateOfEntry: java.sql.Date, foodDateOfPublication: Option[java.sql.Date] = None, countryCode: Option[Int] = None, scientificName: Option[String] = None)
  /** GetResult implicit for fetching FoodNameRow objects using plain SQL queries */
  implicit def GetResultFoodNameRow(implicit e0: GR[Int], e1: GR[String], e2: GR[java.sql.Date], e3: GR[Option[java.sql.Date]], e4: GR[Option[Int]], e5: GR[Option[String]]): GR[FoodNameRow] = GR{
    prs => import prs._
    FoodNameRow.tupled((<<[Int], <<[Int], <<[Int], <<[Int], <<[String], <<[String], <<[java.sql.Date], <<?[java.sql.Date], <<?[Int], <<?[String]))
  }
  /** Table description of table food_name. Objects of this class serve as prototypes for rows in queries. */
  class FoodName(_tableTag: Tag) extends profile.api.Table[FoodNameRow](_tableTag, Some("cnf"), "food_name") {
    def * = (foodId, foodCode, foodGroupId, foodSourceId, foodDescription, foodDescriptionF, foodDateOfEntry, foodDateOfPublication, countryCode, scientificName) <> (FoodNameRow.tupled, FoodNameRow.unapply)
    /** Maps whole row to an option. Useful for outer joins. */
    def ? = ((Rep.Some(foodId), Rep.Some(foodCode), Rep.Some(foodGroupId), Rep.Some(foodSourceId), Rep.Some(foodDescription), Rep.Some(foodDescriptionF), Rep.Some(foodDateOfEntry), foodDateOfPublication, countryCode, scientificName)).shaped.<>({r=>import r._; _1.map(_=> FoodNameRow.tupled((_1.get, _2.get, _3.get, _4.get, _5.get, _6.get, _7.get, _8, _9, _10)))}, (_:Any) =>  throw new Exception("Inserting into ? projection not supported."))

    /** Database column food_id SqlType(int4) */
    val foodId: Rep[Int] = column[Int]("food_id")
    /** Database column food_code SqlType(int4) */
    val foodCode: Rep[Int] = column[Int]("food_code")
    /** Database column food_group_id SqlType(int4) */
    val foodGroupId: Rep[Int] = column[Int]("food_group_id")
    /** Database column food_source_id SqlType(int4) */
    val foodSourceId: Rep[Int] = column[Int]("food_source_id")
    /** Database column food_description SqlType(text) */
    val foodDescription: Rep[String] = column[String]("food_description")
    /** Database column food_description_f SqlType(text) */
    val foodDescriptionF: Rep[String] = column[String]("food_description_f")
    /** Database column food_date_of_entry SqlType(date) */
    val foodDateOfEntry: Rep[java.sql.Date] = column[java.sql.Date]("food_date_of_entry")
    /** Database column food_date_of_publication SqlType(date), Default(None) */
    val foodDateOfPublication: Rep[Option[java.sql.Date]] = column[Option[java.sql.Date]]("food_date_of_publication", O.Default(None))
    /** Database column country_code SqlType(int4), Default(None) */
    val countryCode: Rep[Option[Int]] = column[Option[Int]]("country_code", O.Default(None))
    /** Database column scientific_name SqlType(text), Default(None) */
    val scientificName: Rep[Option[String]] = column[Option[String]]("scientific_name", O.Default(None))

    /** Primary key of FoodName (database name food_name_pk) */
    val pk = primaryKey("food_name_pk", (foodId, foodGroupId, foodSourceId))

    /** Foreign key referencing FoodGroup (database name food_name_food_group_id_fk) */
    lazy val foodGroupFk = foreignKey("food_name_food_group_id_fk", foodGroupId, FoodGroup)(r => r.foodGroupId, onUpdate=ForeignKeyAction.NoAction, onDelete=ForeignKeyAction.NoAction)

    /** Uniqueness Index over (foodId) (database name food_name_food_id_key) */
    val index1 = index("food_name_food_id_key", foodId, unique=true)
  }
  /** Collection-like TableQuery object for table FoodName */
  lazy val FoodName = new TableQuery(tag => new FoodName(tag))

  /** Entity class storing rows of table FoodSource
   *  @param foodSourceId Database column food_source_id SqlType(int4), PrimaryKey
   *  @param foodSourceCode Database column food_source_code SqlType(int4)
   *  @param foodSourceDescription Database column food_source_description SqlType(text), Default(None)
   *  @param foodSourceDescriptionF Database column food_source_description_f SqlType(text), Default(None) */
  case class FoodSourceRow(foodSourceId: Int, foodSourceCode: Int, foodSourceDescription: Option[String] = None, foodSourceDescriptionF: Option[String] = None)
  /** GetResult implicit for fetching FoodSourceRow objects using plain SQL queries */
  implicit def GetResultFoodSourceRow(implicit e0: GR[Int], e1: GR[Option[String]]): GR[FoodSourceRow] = GR{
    prs => import prs._
    FoodSourceRow.tupled((<<[Int], <<[Int], <<?[String], <<?[String]))
  }
  /** Table description of table food_source. Objects of this class serve as prototypes for rows in queries. */
  class FoodSource(_tableTag: Tag) extends profile.api.Table[FoodSourceRow](_tableTag, Some("cnf"), "food_source") {
    def * = (foodSourceId, foodSourceCode, foodSourceDescription, foodSourceDescriptionF) <> (FoodSourceRow.tupled, FoodSourceRow.unapply)
    /** Maps whole row to an option. Useful for outer joins. */
    def ? = ((Rep.Some(foodSourceId), Rep.Some(foodSourceCode), foodSourceDescription, foodSourceDescriptionF)).shaped.<>({r=>import r._; _1.map(_=> FoodSourceRow.tupled((_1.get, _2.get, _3, _4)))}, (_:Any) =>  throw new Exception("Inserting into ? projection not supported."))

    /** Database column food_source_id SqlType(int4), PrimaryKey */
    val foodSourceId: Rep[Int] = column[Int]("food_source_id", O.PrimaryKey)
    /** Database column food_source_code SqlType(int4) */
    val foodSourceCode: Rep[Int] = column[Int]("food_source_code")
    /** Database column food_source_description SqlType(text), Default(None) */
    val foodSourceDescription: Rep[Option[String]] = column[Option[String]]("food_source_description", O.Default(None))
    /** Database column food_source_description_f SqlType(text), Default(None) */
    val foodSourceDescriptionF: Rep[Option[String]] = column[Option[String]]("food_source_description_f", O.Default(None))
  }
  /** Collection-like TableQuery object for table FoodSource */
  lazy val FoodSource = new TableQuery(tag => new FoodSource(tag))

  /** Entity class storing rows of table Meal
   *  @param id Database column id SqlType(uuid), PrimaryKey
   *  @param userId Database column user_id SqlType(uuid)
   *  @param consumedOnDate Database column consumed_on_date SqlType(date)
   *  @param consumedOnTime Database column consumed_on_time SqlType(time), Default(None)
   *  @param name Database column name SqlType(text), Default(None) */
  case class MealRow(id: java.util.UUID, userId: java.util.UUID, consumedOnDate: java.sql.Date, consumedOnTime: Option[java.sql.Time] = None, name: Option[String] = None)
  /** GetResult implicit for fetching MealRow objects using plain SQL queries */
  implicit def GetResultMealRow(implicit e0: GR[java.util.UUID], e1: GR[java.sql.Date], e2: GR[Option[java.sql.Time]], e3: GR[Option[String]]): GR[MealRow] = GR{
    prs => import prs._
    MealRow.tupled((<<[java.util.UUID], <<[java.util.UUID], <<[java.sql.Date], <<?[java.sql.Time], <<?[String]))
  }
  /** Table description of table meal. Objects of this class serve as prototypes for rows in queries. */
  class Meal(_tableTag: Tag) extends profile.api.Table[MealRow](_tableTag, "meal") {
    def * = (id, userId, consumedOnDate, consumedOnTime, name) <> (MealRow.tupled, MealRow.unapply)
    /** Maps whole row to an option. Useful for outer joins. */
    def ? = ((Rep.Some(id), Rep.Some(userId), Rep.Some(consumedOnDate), consumedOnTime, name)).shaped.<>({r=>import r._; _1.map(_=> MealRow.tupled((_1.get, _2.get, _3.get, _4, _5)))}, (_:Any) =>  throw new Exception("Inserting into ? projection not supported."))

    /** Database column id SqlType(uuid), PrimaryKey */
    val id: Rep[java.util.UUID] = column[java.util.UUID]("id", O.PrimaryKey)
    /** Database column user_id SqlType(uuid) */
    val userId: Rep[java.util.UUID] = column[java.util.UUID]("user_id")
    /** Database column consumed_on_date SqlType(date) */
    val consumedOnDate: Rep[java.sql.Date] = column[java.sql.Date]("consumed_on_date")
    /** Database column consumed_on_time SqlType(time), Default(None) */
    val consumedOnTime: Rep[Option[java.sql.Time]] = column[Option[java.sql.Time]]("consumed_on_time", O.Default(None))
    /** Database column name SqlType(text), Default(None) */
    val name: Rep[Option[String]] = column[Option[String]]("name", O.Default(None))

    /** Foreign key referencing User (database name meal_user_id_fk) */
    lazy val userFk = foreignKey("meal_user_id_fk", userId, User)(r => r.id, onUpdate=ForeignKeyAction.NoAction, onDelete=ForeignKeyAction.Cascade)
  }
  /** Collection-like TableQuery object for table Meal */
  lazy val Meal = new TableQuery(tag => new Meal(tag))

  /** Entity class storing rows of table MealEntry
   *  @param id Database column id SqlType(uuid), PrimaryKey
   *  @param mealId Database column meal_id SqlType(uuid)
   *  @param recipeId Database column recipe_id SqlType(uuid)
   *  @param numberOfServings Database column number_of_servings SqlType(numeric) */
  case class MealEntryRow(id: java.util.UUID, mealId: java.util.UUID, recipeId: java.util.UUID, numberOfServings: scala.math.BigDecimal)
  /** GetResult implicit for fetching MealEntryRow objects using plain SQL queries */
  implicit def GetResultMealEntryRow(implicit e0: GR[java.util.UUID], e1: GR[scala.math.BigDecimal]): GR[MealEntryRow] = GR{
    prs => import prs._
    MealEntryRow.tupled((<<[java.util.UUID], <<[java.util.UUID], <<[java.util.UUID], <<[scala.math.BigDecimal]))
  }
  /** Table description of table meal_entry. Objects of this class serve as prototypes for rows in queries. */
  class MealEntry(_tableTag: Tag) extends profile.api.Table[MealEntryRow](_tableTag, "meal_entry") {
    def * = (id, mealId, recipeId, numberOfServings) <> (MealEntryRow.tupled, MealEntryRow.unapply)
    /** Maps whole row to an option. Useful for outer joins. */
    def ? = ((Rep.Some(id), Rep.Some(mealId), Rep.Some(recipeId), Rep.Some(numberOfServings))).shaped.<>({r=>import r._; _1.map(_=> MealEntryRow.tupled((_1.get, _2.get, _3.get, _4.get)))}, (_:Any) =>  throw new Exception("Inserting into ? projection not supported."))

    /** Database column id SqlType(uuid), PrimaryKey */
    val id: Rep[java.util.UUID] = column[java.util.UUID]("id", O.PrimaryKey)
    /** Database column meal_id SqlType(uuid) */
    val mealId: Rep[java.util.UUID] = column[java.util.UUID]("meal_id")
    /** Database column recipe_id SqlType(uuid) */
    val recipeId: Rep[java.util.UUID] = column[java.util.UUID]("recipe_id")
    /** Database column number_of_servings SqlType(numeric) */
    val numberOfServings: Rep[scala.math.BigDecimal] = column[scala.math.BigDecimal]("number_of_servings")

    /** Foreign key referencing Meal (database name meal_entry_meal_id_fk) */
    lazy val mealFk = foreignKey("meal_entry_meal_id_fk", mealId, Meal)(r => r.id, onUpdate=ForeignKeyAction.NoAction, onDelete=ForeignKeyAction.Cascade)
    /** Foreign key referencing Recipe (database name meal_entry_recipe_id_fk) */
    lazy val recipeFk = foreignKey("meal_entry_recipe_id_fk", recipeId, Recipe)(r => r.id, onUpdate=ForeignKeyAction.NoAction, onDelete=ForeignKeyAction.Cascade)
  }
  /** Collection-like TableQuery object for table MealEntry */
  lazy val MealEntry = new TableQuery(tag => new MealEntry(tag))

  /** Entity class storing rows of table MeasureName
   *  @param measureId Database column measure_id SqlType(int4), PrimaryKey
   *  @param measureDescription Database column measure_description SqlType(text)
   *  @param measureDescriptionF Database column measure_description_f SqlType(text) */
  case class MeasureNameRow(measureId: Int, measureDescription: String, measureDescriptionF: String)
  /** GetResult implicit for fetching MeasureNameRow objects using plain SQL queries */
  implicit def GetResultMeasureNameRow(implicit e0: GR[Int], e1: GR[String]): GR[MeasureNameRow] = GR{
    prs => import prs._
    MeasureNameRow.tupled((<<[Int], <<[String], <<[String]))
  }
  /** Table description of table measure_name. Objects of this class serve as prototypes for rows in queries. */
  class MeasureName(_tableTag: Tag) extends profile.api.Table[MeasureNameRow](_tableTag, Some("cnf"), "measure_name") {
    def * = (measureId, measureDescription, measureDescriptionF) <> (MeasureNameRow.tupled, MeasureNameRow.unapply)
    /** Maps whole row to an option. Useful for outer joins. */
    def ? = ((Rep.Some(measureId), Rep.Some(measureDescription), Rep.Some(measureDescriptionF))).shaped.<>({r=>import r._; _1.map(_=> MeasureNameRow.tupled((_1.get, _2.get, _3.get)))}, (_:Any) =>  throw new Exception("Inserting into ? projection not supported."))

    /** Database column measure_id SqlType(int4), PrimaryKey */
    val measureId: Rep[Int] = column[Int]("measure_id", O.PrimaryKey)
    /** Database column measure_description SqlType(text) */
    val measureDescription: Rep[String] = column[String]("measure_description")
    /** Database column measure_description_f SqlType(text) */
    val measureDescriptionF: Rep[String] = column[String]("measure_description_f")
  }
  /** Collection-like TableQuery object for table MeasureName */
  lazy val MeasureName = new TableQuery(tag => new MeasureName(tag))

  /** Entity class storing rows of table NutrientAmount
   *  @param foodId Database column food_id SqlType(int4)
   *  @param nutrientId Database column nutrient_id SqlType(int4)
   *  @param nutrientValue Database column nutrient_value SqlType(numeric)
   *  @param standardError Database column standard_error SqlType(numeric), Default(None)
   *  @param numberOfObservation Database column number_of_observation SqlType(int4), Default(None)
   *  @param nutrientSourceId Database column nutrient_source_id SqlType(int4)
   *  @param nutrientDateOfEntry Database column nutrient_date_of_entry SqlType(date), Default(None) */
  case class NutrientAmountRow(foodId: Int, nutrientId: Int, nutrientValue: scala.math.BigDecimal, standardError: Option[scala.math.BigDecimal] = None, numberOfObservation: Option[Int] = None, nutrientSourceId: Int, nutrientDateOfEntry: Option[java.sql.Date] = None)
  /** GetResult implicit for fetching NutrientAmountRow objects using plain SQL queries */
  implicit def GetResultNutrientAmountRow(implicit e0: GR[Int], e1: GR[scala.math.BigDecimal], e2: GR[Option[scala.math.BigDecimal]], e3: GR[Option[Int]], e4: GR[Option[java.sql.Date]]): GR[NutrientAmountRow] = GR{
    prs => import prs._
    NutrientAmountRow.tupled((<<[Int], <<[Int], <<[scala.math.BigDecimal], <<?[scala.math.BigDecimal], <<?[Int], <<[Int], <<?[java.sql.Date]))
  }
  /** Table description of table nutrient_amount. Objects of this class serve as prototypes for rows in queries. */
  class NutrientAmount(_tableTag: Tag) extends profile.api.Table[NutrientAmountRow](_tableTag, Some("cnf"), "nutrient_amount") {
    def * = (foodId, nutrientId, nutrientValue, standardError, numberOfObservation, nutrientSourceId, nutrientDateOfEntry) <> (NutrientAmountRow.tupled, NutrientAmountRow.unapply)
    /** Maps whole row to an option. Useful for outer joins. */
    def ? = ((Rep.Some(foodId), Rep.Some(nutrientId), Rep.Some(nutrientValue), standardError, numberOfObservation, Rep.Some(nutrientSourceId), nutrientDateOfEntry)).shaped.<>({r=>import r._; _1.map(_=> NutrientAmountRow.tupled((_1.get, _2.get, _3.get, _4, _5, _6.get, _7)))}, (_:Any) =>  throw new Exception("Inserting into ? projection not supported."))

    /** Database column food_id SqlType(int4) */
    val foodId: Rep[Int] = column[Int]("food_id")
    /** Database column nutrient_id SqlType(int4) */
    val nutrientId: Rep[Int] = column[Int]("nutrient_id")
    /** Database column nutrient_value SqlType(numeric) */
    val nutrientValue: Rep[scala.math.BigDecimal] = column[scala.math.BigDecimal]("nutrient_value")
    /** Database column standard_error SqlType(numeric), Default(None) */
    val standardError: Rep[Option[scala.math.BigDecimal]] = column[Option[scala.math.BigDecimal]]("standard_error", O.Default(None))
    /** Database column number_of_observation SqlType(int4), Default(None) */
    val numberOfObservation: Rep[Option[Int]] = column[Option[Int]]("number_of_observation", O.Default(None))
    /** Database column nutrient_source_id SqlType(int4) */
    val nutrientSourceId: Rep[Int] = column[Int]("nutrient_source_id")
    /** Database column nutrient_date_of_entry SqlType(date), Default(None) */
    val nutrientDateOfEntry: Rep[Option[java.sql.Date]] = column[Option[java.sql.Date]]("nutrient_date_of_entry", O.Default(None))

    /** Primary key of NutrientAmount (database name nutrient_amount_pk) */
    val pk = primaryKey("nutrient_amount_pk", (foodId, nutrientId, nutrientSourceId))

    /** Foreign key referencing NutrientSource (database name nutrient_amount_nutrient_source_id_fk) */
    lazy val nutrientSourceFk = foreignKey("nutrient_amount_nutrient_source_id_fk", nutrientSourceId, NutrientSource)(r => r.nutrientSourceId, onUpdate=ForeignKeyAction.NoAction, onDelete=ForeignKeyAction.NoAction)
  }
  /** Collection-like TableQuery object for table NutrientAmount */
  lazy val NutrientAmount = new TableQuery(tag => new NutrientAmount(tag))

  /** Entity class storing rows of table NutrientName
   *  @param nutrientNameId Database column nutrient_name_id SqlType(int4)
   *  @param nutrientCode Database column nutrient_code SqlType(int4), PrimaryKey
   *  @param nutrientSymbol Database column nutrient_symbol SqlType(text)
   *  @param nutrientUnit Database column nutrient_unit SqlType(text)
   *  @param nutrientName Database column nutrient_name SqlType(text)
   *  @param nutrientNameF Database column nutrient_name_f SqlType(text)
   *  @param tagname Database column tagname SqlType(text), Default(None)
   *  @param nutrientDecimals Database column nutrient_decimals SqlType(int4) */
  case class NutrientNameRow(nutrientNameId: Int, nutrientCode: Int, nutrientSymbol: String, nutrientUnit: String, nutrientName: String, nutrientNameF: String, tagname: Option[String] = None, nutrientDecimals: Int)
  /** GetResult implicit for fetching NutrientNameRow objects using plain SQL queries */
  implicit def GetResultNutrientNameRow(implicit e0: GR[Int], e1: GR[String], e2: GR[Option[String]]): GR[NutrientNameRow] = GR{
    prs => import prs._
    NutrientNameRow.tupled((<<[Int], <<[Int], <<[String], <<[String], <<[String], <<[String], <<?[String], <<[Int]))
  }
  /** Table description of table nutrient_name. Objects of this class serve as prototypes for rows in queries. */
  class NutrientName(_tableTag: Tag) extends profile.api.Table[NutrientNameRow](_tableTag, Some("cnf"), "nutrient_name") {
    def * = (nutrientNameId, nutrientCode, nutrientSymbol, nutrientUnit, nutrientName, nutrientNameF, tagname, nutrientDecimals) <> (NutrientNameRow.tupled, NutrientNameRow.unapply)
    /** Maps whole row to an option. Useful for outer joins. */
    def ? = ((Rep.Some(nutrientNameId), Rep.Some(nutrientCode), Rep.Some(nutrientSymbol), Rep.Some(nutrientUnit), Rep.Some(nutrientName), Rep.Some(nutrientNameF), tagname, Rep.Some(nutrientDecimals))).shaped.<>({r=>import r._; _1.map(_=> NutrientNameRow.tupled((_1.get, _2.get, _3.get, _4.get, _5.get, _6.get, _7, _8.get)))}, (_:Any) =>  throw new Exception("Inserting into ? projection not supported."))

    /** Database column nutrient_name_id SqlType(int4) */
    val nutrientNameId: Rep[Int] = column[Int]("nutrient_name_id")
    /** Database column nutrient_code SqlType(int4), PrimaryKey */
    val nutrientCode: Rep[Int] = column[Int]("nutrient_code", O.PrimaryKey)
    /** Database column nutrient_symbol SqlType(text) */
    val nutrientSymbol: Rep[String] = column[String]("nutrient_symbol")
    /** Database column nutrient_unit SqlType(text) */
    val nutrientUnit: Rep[String] = column[String]("nutrient_unit")
    /** Database column nutrient_name SqlType(text) */
    val nutrientName: Rep[String] = column[String]("nutrient_name")
    /** Database column nutrient_name_f SqlType(text) */
    val nutrientNameF: Rep[String] = column[String]("nutrient_name_f")
    /** Database column tagname SqlType(text), Default(None) */
    val tagname: Rep[Option[String]] = column[Option[String]]("tagname", O.Default(None))
    /** Database column nutrient_decimals SqlType(int4) */
    val nutrientDecimals: Rep[Int] = column[Int]("nutrient_decimals")
  }
  /** Collection-like TableQuery object for table NutrientName */
  lazy val NutrientName = new TableQuery(tag => new NutrientName(tag))

  /** Entity class storing rows of table NutrientSource
   *  @param nutrientSourceId Database column nutrient_source_id SqlType(int4), PrimaryKey
   *  @param nutrientSourceCode Database column nutrient_source_code SqlType(int4)
   *  @param nutrientSourceDescription Database column nutrient_source_description SqlType(text), Default(None)
   *  @param nutrientSourceDescriptionF Database column nutrient_source_description_f SqlType(text), Default(None) */
  case class NutrientSourceRow(nutrientSourceId: Int, nutrientSourceCode: Int, nutrientSourceDescription: Option[String] = None, nutrientSourceDescriptionF: Option[String] = None)
  /** GetResult implicit for fetching NutrientSourceRow objects using plain SQL queries */
  implicit def GetResultNutrientSourceRow(implicit e0: GR[Int], e1: GR[Option[String]]): GR[NutrientSourceRow] = GR{
    prs => import prs._
    NutrientSourceRow.tupled((<<[Int], <<[Int], <<?[String], <<?[String]))
  }
  /** Table description of table nutrient_source. Objects of this class serve as prototypes for rows in queries. */
  class NutrientSource(_tableTag: Tag) extends profile.api.Table[NutrientSourceRow](_tableTag, Some("cnf"), "nutrient_source") {
    def * = (nutrientSourceId, nutrientSourceCode, nutrientSourceDescription, nutrientSourceDescriptionF) <> (NutrientSourceRow.tupled, NutrientSourceRow.unapply)
    /** Maps whole row to an option. Useful for outer joins. */
    def ? = ((Rep.Some(nutrientSourceId), Rep.Some(nutrientSourceCode), nutrientSourceDescription, nutrientSourceDescriptionF)).shaped.<>({r=>import r._; _1.map(_=> NutrientSourceRow.tupled((_1.get, _2.get, _3, _4)))}, (_:Any) =>  throw new Exception("Inserting into ? projection not supported."))

    /** Database column nutrient_source_id SqlType(int4), PrimaryKey */
    val nutrientSourceId: Rep[Int] = column[Int]("nutrient_source_id", O.PrimaryKey)
    /** Database column nutrient_source_code SqlType(int4) */
    val nutrientSourceCode: Rep[Int] = column[Int]("nutrient_source_code")
    /** Database column nutrient_source_description SqlType(text), Default(None) */
    val nutrientSourceDescription: Rep[Option[String]] = column[Option[String]]("nutrient_source_description", O.Default(None))
    /** Database column nutrient_source_description_f SqlType(text), Default(None) */
    val nutrientSourceDescriptionF: Rep[Option[String]] = column[Option[String]]("nutrient_source_description_f", O.Default(None))
  }
  /** Collection-like TableQuery object for table NutrientSource */
  lazy val NutrientSource = new TableQuery(tag => new NutrientSource(tag))

  /** Entity class storing rows of table Recipe
   *  @param id Database column id SqlType(uuid), PrimaryKey
   *  @param userId Database column user_id SqlType(uuid)
   *  @param name Database column name SqlType(text)
   *  @param description Database column description SqlType(text), Default(None)
   *  @param numberOfServings Database column number_of_servings SqlType(numeric) */
  case class RecipeRow(id: java.util.UUID, userId: java.util.UUID, name: String, description: Option[String] = None, numberOfServings: scala.math.BigDecimal)
  /** GetResult implicit for fetching RecipeRow objects using plain SQL queries */
  implicit def GetResultRecipeRow(implicit e0: GR[java.util.UUID], e1: GR[String], e2: GR[Option[String]], e3: GR[scala.math.BigDecimal]): GR[RecipeRow] = GR{
    prs => import prs._
    RecipeRow.tupled((<<[java.util.UUID], <<[java.util.UUID], <<[String], <<?[String], <<[scala.math.BigDecimal]))
  }
  /** Table description of table recipe. Objects of this class serve as prototypes for rows in queries. */
  class Recipe(_tableTag: Tag) extends profile.api.Table[RecipeRow](_tableTag, "recipe") {
    def * = (id, userId, name, description, numberOfServings) <> (RecipeRow.tupled, RecipeRow.unapply)
    /** Maps whole row to an option. Useful for outer joins. */
    def ? = ((Rep.Some(id), Rep.Some(userId), Rep.Some(name), description, Rep.Some(numberOfServings))).shaped.<>({r=>import r._; _1.map(_=> RecipeRow.tupled((_1.get, _2.get, _3.get, _4, _5.get)))}, (_:Any) =>  throw new Exception("Inserting into ? projection not supported."))

    /** Database column id SqlType(uuid), PrimaryKey */
    val id: Rep[java.util.UUID] = column[java.util.UUID]("id", O.PrimaryKey)
    /** Database column user_id SqlType(uuid) */
    val userId: Rep[java.util.UUID] = column[java.util.UUID]("user_id")
    /** Database column name SqlType(text) */
    val name: Rep[String] = column[String]("name")
    /** Database column description SqlType(text), Default(None) */
    val description: Rep[Option[String]] = column[Option[String]]("description", O.Default(None))
    /** Database column number_of_servings SqlType(numeric) */
    val numberOfServings: Rep[scala.math.BigDecimal] = column[scala.math.BigDecimal]("number_of_servings")

    /** Foreign key referencing User (database name recipe_user_id_fk) */
    lazy val userFk = foreignKey("recipe_user_id_fk", userId, User)(r => r.id, onUpdate=ForeignKeyAction.NoAction, onDelete=ForeignKeyAction.Cascade)
  }
  /** Collection-like TableQuery object for table Recipe */
  lazy val Recipe = new TableQuery(tag => new Recipe(tag))

  /** Entity class storing rows of table RecipeIngredient
   *  @param id Database column id SqlType(uuid), PrimaryKey
   *  @param recipeId Database column recipe_id SqlType(uuid)
   *  @param foodNameId Database column food_name_id SqlType(int4)
   *  @param measureId Database column measure_id SqlType(int4)
   *  @param factor Database column factor SqlType(numeric) */
  case class RecipeIngredientRow(id: java.util.UUID, recipeId: java.util.UUID, foodNameId: Int, measureId: Int, factor: scala.math.BigDecimal)
  /** GetResult implicit for fetching RecipeIngredientRow objects using plain SQL queries */
  implicit def GetResultRecipeIngredientRow(implicit e0: GR[java.util.UUID], e1: GR[Int], e2: GR[scala.math.BigDecimal]): GR[RecipeIngredientRow] = GR{
    prs => import prs._
    RecipeIngredientRow.tupled((<<[java.util.UUID], <<[java.util.UUID], <<[Int], <<[Int], <<[scala.math.BigDecimal]))
  }
  /** Table description of table recipe_ingredient. Objects of this class serve as prototypes for rows in queries. */
  class RecipeIngredient(_tableTag: Tag) extends profile.api.Table[RecipeIngredientRow](_tableTag, "recipe_ingredient") {
    def * = (id, recipeId, foodNameId, measureId, factor) <> (RecipeIngredientRow.tupled, RecipeIngredientRow.unapply)
    /** Maps whole row to an option. Useful for outer joins. */
    def ? = ((Rep.Some(id), Rep.Some(recipeId), Rep.Some(foodNameId), Rep.Some(measureId), Rep.Some(factor))).shaped.<>({r=>import r._; _1.map(_=> RecipeIngredientRow.tupled((_1.get, _2.get, _3.get, _4.get, _5.get)))}, (_:Any) =>  throw new Exception("Inserting into ? projection not supported."))

    /** Database column id SqlType(uuid), PrimaryKey */
    val id: Rep[java.util.UUID] = column[java.util.UUID]("id", O.PrimaryKey)
    /** Database column recipe_id SqlType(uuid) */
    val recipeId: Rep[java.util.UUID] = column[java.util.UUID]("recipe_id")
    /** Database column food_name_id SqlType(int4) */
    val foodNameId: Rep[Int] = column[Int]("food_name_id")
    /** Database column measure_id SqlType(int4) */
    val measureId: Rep[Int] = column[Int]("measure_id")
    /** Database column factor SqlType(numeric) */
    val factor: Rep[scala.math.BigDecimal] = column[scala.math.BigDecimal]("factor")

    /** Foreign key referencing ConversionFactor (database name recipe_ingredient_food_name_id_measure_id_fk) */
    lazy val conversionFactorFk = foreignKey("recipe_ingredient_food_name_id_measure_id_fk", (foodNameId, measureId), ConversionFactor)(r => (r.foodId, r.measureId), onUpdate=ForeignKeyAction.NoAction, onDelete=ForeignKeyAction.NoAction)
    /** Foreign key referencing FoodName (database name recipe_ingredient_food_name_id_fk) */
    lazy val foodNameFk = foreignKey("recipe_ingredient_food_name_id_fk", foodNameId, FoodName)(r => r.foodId, onUpdate=ForeignKeyAction.NoAction, onDelete=ForeignKeyAction.NoAction)
    /** Foreign key referencing MeasureName (database name recipe_ingredient_measure_id_fk) */
    lazy val measureNameFk = foreignKey("recipe_ingredient_measure_id_fk", measureId, MeasureName)(r => r.measureId, onUpdate=ForeignKeyAction.NoAction, onDelete=ForeignKeyAction.NoAction)
    /** Foreign key referencing Recipe (database name recipe_ingredient_recipe_id_fk) */
    lazy val recipeFk = foreignKey("recipe_ingredient_recipe_id_fk", recipeId, Recipe)(r => r.id, onUpdate=ForeignKeyAction.NoAction, onDelete=ForeignKeyAction.Cascade)
  }
  /** Collection-like TableQuery object for table RecipeIngredient */
  lazy val RecipeIngredient = new TableQuery(tag => new RecipeIngredient(tag))

  /** Entity class storing rows of table ReferenceEntry
   *  @param referenceMapId Database column reference_map_id SqlType(uuid)
   *  @param nutrientCode Database column nutrient_code SqlType(int4)
   *  @param amount Database column amount SqlType(numeric) */
  case class ReferenceEntryRow(referenceMapId: java.util.UUID, nutrientCode: Int, amount: scala.math.BigDecimal)
  /** GetResult implicit for fetching ReferenceEntryRow objects using plain SQL queries */
  implicit def GetResultReferenceEntryRow(implicit e0: GR[java.util.UUID], e1: GR[Int], e2: GR[scala.math.BigDecimal]): GR[ReferenceEntryRow] = GR{
    prs => import prs._
    ReferenceEntryRow.tupled((<<[java.util.UUID], <<[Int], <<[scala.math.BigDecimal]))
  }
  /** Table description of table reference_entry. Objects of this class serve as prototypes for rows in queries. */
  class ReferenceEntry(_tableTag: Tag) extends profile.api.Table[ReferenceEntryRow](_tableTag, "reference_entry") {
    def * = (referenceMapId, nutrientCode, amount) <> (ReferenceEntryRow.tupled, ReferenceEntryRow.unapply)
    /** Maps whole row to an option. Useful for outer joins. */
    def ? = ((Rep.Some(referenceMapId), Rep.Some(nutrientCode), Rep.Some(amount))).shaped.<>({r=>import r._; _1.map(_=> ReferenceEntryRow.tupled((_1.get, _2.get, _3.get)))}, (_:Any) =>  throw new Exception("Inserting into ? projection not supported."))

    /** Database column reference_map_id SqlType(uuid) */
    val referenceMapId: Rep[java.util.UUID] = column[java.util.UUID]("reference_map_id")
    /** Database column nutrient_code SqlType(int4) */
    val nutrientCode: Rep[Int] = column[Int]("nutrient_code")
    /** Database column amount SqlType(numeric) */
    val amount: Rep[scala.math.BigDecimal] = column[scala.math.BigDecimal]("amount")

    /** Primary key of ReferenceEntry (database name reference_entry_pk) */
    val pk = primaryKey("reference_entry_pk", (referenceMapId, nutrientCode))

    /** Foreign key referencing NutrientName (database name reference_entry_nutrient_code_fk) */
    lazy val nutrientNameFk = foreignKey("reference_entry_nutrient_code_fk", nutrientCode, NutrientName)(r => r.nutrientCode, onUpdate=ForeignKeyAction.NoAction, onDelete=ForeignKeyAction.Cascade)
    /** Foreign key referencing ReferenceMap (database name reference_entry_reference_map_id_fk) */
    lazy val referenceMapFk = foreignKey("reference_entry_reference_map_id_fk", referenceMapId, ReferenceMap)(r => r.id, onUpdate=ForeignKeyAction.NoAction, onDelete=ForeignKeyAction.Cascade)
  }
  /** Collection-like TableQuery object for table ReferenceEntry */
  lazy val ReferenceEntry = new TableQuery(tag => new ReferenceEntry(tag))

  /** Entity class storing rows of table ReferenceMap
   *  @param id Database column id SqlType(uuid), PrimaryKey
   *  @param name Database column name SqlType(text)
   *  @param userId Database column user_id SqlType(uuid) */
  case class ReferenceMapRow(id: java.util.UUID, name: String, userId: java.util.UUID)
  /** GetResult implicit for fetching ReferenceMapRow objects using plain SQL queries */
  implicit def GetResultReferenceMapRow(implicit e0: GR[java.util.UUID], e1: GR[String]): GR[ReferenceMapRow] = GR{
    prs => import prs._
    ReferenceMapRow.tupled((<<[java.util.UUID], <<[String], <<[java.util.UUID]))
  }
  /** Table description of table reference_map. Objects of this class serve as prototypes for rows in queries. */
  class ReferenceMap(_tableTag: Tag) extends profile.api.Table[ReferenceMapRow](_tableTag, "reference_map") {
    def * = (id, name, userId) <> (ReferenceMapRow.tupled, ReferenceMapRow.unapply)
    /** Maps whole row to an option. Useful for outer joins. */
    def ? = ((Rep.Some(id), Rep.Some(name), Rep.Some(userId))).shaped.<>({r=>import r._; _1.map(_=> ReferenceMapRow.tupled((_1.get, _2.get, _3.get)))}, (_:Any) =>  throw new Exception("Inserting into ? projection not supported."))

    /** Database column id SqlType(uuid), PrimaryKey */
    val id: Rep[java.util.UUID] = column[java.util.UUID]("id", O.PrimaryKey)
    /** Database column name SqlType(text) */
    val name: Rep[String] = column[String]("name")
    /** Database column user_id SqlType(uuid) */
    val userId: Rep[java.util.UUID] = column[java.util.UUID]("user_id")

    /** Foreign key referencing User (database name reference_map_user_id_fk) */
    lazy val userFk = foreignKey("reference_map_user_id_fk", userId, User)(r => r.id, onUpdate=ForeignKeyAction.NoAction, onDelete=ForeignKeyAction.Cascade)
  }
  /** Collection-like TableQuery object for table ReferenceMap */
  lazy val ReferenceMap = new TableQuery(tag => new ReferenceMap(tag))

  /** Entity class storing rows of table RefuseAmount
   *  @param foodId Database column food_id SqlType(int4)
   *  @param refuseId Database column refuse_id SqlType(int4)
   *  @param refuseAmount Database column refuse_amount SqlType(int4)
   *  @param refuseDateOfEntry Database column refuse_date_of_entry SqlType(date) */
  case class RefuseAmountRow(foodId: Int, refuseId: Int, refuseAmount: Int, refuseDateOfEntry: java.sql.Date)
  /** GetResult implicit for fetching RefuseAmountRow objects using plain SQL queries */
  implicit def GetResultRefuseAmountRow(implicit e0: GR[Int], e1: GR[java.sql.Date]): GR[RefuseAmountRow] = GR{
    prs => import prs._
    RefuseAmountRow.tupled((<<[Int], <<[Int], <<[Int], <<[java.sql.Date]))
  }
  /** Table description of table refuse_amount. Objects of this class serve as prototypes for rows in queries. */
  class RefuseAmount(_tableTag: Tag) extends profile.api.Table[RefuseAmountRow](_tableTag, Some("cnf"), "refuse_amount") {
    def * = (foodId, refuseId, refuseAmount, refuseDateOfEntry) <> (RefuseAmountRow.tupled, RefuseAmountRow.unapply)
    /** Maps whole row to an option. Useful for outer joins. */
    def ? = ((Rep.Some(foodId), Rep.Some(refuseId), Rep.Some(refuseAmount), Rep.Some(refuseDateOfEntry))).shaped.<>({r=>import r._; _1.map(_=> RefuseAmountRow.tupled((_1.get, _2.get, _3.get, _4.get)))}, (_:Any) =>  throw new Exception("Inserting into ? projection not supported."))

    /** Database column food_id SqlType(int4) */
    val foodId: Rep[Int] = column[Int]("food_id")
    /** Database column refuse_id SqlType(int4) */
    val refuseId: Rep[Int] = column[Int]("refuse_id")
    /** Database column refuse_amount SqlType(int4) */
    val refuseAmount: Rep[Int] = column[Int]("refuse_amount")
    /** Database column refuse_date_of_entry SqlType(date) */
    val refuseDateOfEntry: Rep[java.sql.Date] = column[java.sql.Date]("refuse_date_of_entry")

    /** Primary key of RefuseAmount (database name refuse_amount_pk) */
    val pk = primaryKey("refuse_amount_pk", (foodId, refuseId))

    /** Foreign key referencing RefuseName (database name refuse_amount_refuse_id_fk) */
    lazy val refuseNameFk = foreignKey("refuse_amount_refuse_id_fk", refuseId, RefuseName)(r => r.refuseId, onUpdate=ForeignKeyAction.NoAction, onDelete=ForeignKeyAction.NoAction)
  }
  /** Collection-like TableQuery object for table RefuseAmount */
  lazy val RefuseAmount = new TableQuery(tag => new RefuseAmount(tag))

  /** Entity class storing rows of table RefuseName
   *  @param refuseId Database column refuse_id SqlType(int4), PrimaryKey
   *  @param refuseDescription Database column refuse_description SqlType(text)
   *  @param refuseDescriptionF Database column refuse_description_f SqlType(text) */
  case class RefuseNameRow(refuseId: Int, refuseDescription: String, refuseDescriptionF: String)
  /** GetResult implicit for fetching RefuseNameRow objects using plain SQL queries */
  implicit def GetResultRefuseNameRow(implicit e0: GR[Int], e1: GR[String]): GR[RefuseNameRow] = GR{
    prs => import prs._
    RefuseNameRow.tupled((<<[Int], <<[String], <<[String]))
  }
  /** Table description of table refuse_name. Objects of this class serve as prototypes for rows in queries. */
  class RefuseName(_tableTag: Tag) extends profile.api.Table[RefuseNameRow](_tableTag, Some("cnf"), "refuse_name") {
    def * = (refuseId, refuseDescription, refuseDescriptionF) <> (RefuseNameRow.tupled, RefuseNameRow.unapply)
    /** Maps whole row to an option. Useful for outer joins. */
    def ? = ((Rep.Some(refuseId), Rep.Some(refuseDescription), Rep.Some(refuseDescriptionF))).shaped.<>({r=>import r._; _1.map(_=> RefuseNameRow.tupled((_1.get, _2.get, _3.get)))}, (_:Any) =>  throw new Exception("Inserting into ? projection not supported."))

    /** Database column refuse_id SqlType(int4), PrimaryKey */
    val refuseId: Rep[Int] = column[Int]("refuse_id", O.PrimaryKey)
    /** Database column refuse_description SqlType(text) */
    val refuseDescription: Rep[String] = column[String]("refuse_description")
    /** Database column refuse_description_f SqlType(text) */
    val refuseDescriptionF: Rep[String] = column[String]("refuse_description_f")
  }
  /** Collection-like TableQuery object for table RefuseName */
  lazy val RefuseName = new TableQuery(tag => new RefuseName(tag))

  /** Entity class storing rows of table Session
   *  @param id Database column id SqlType(uuid), PrimaryKey
   *  @param userId Database column user_id SqlType(uuid) */
  case class SessionRow(id: java.util.UUID, userId: java.util.UUID)
  /** GetResult implicit for fetching SessionRow objects using plain SQL queries */
  implicit def GetResultSessionRow(implicit e0: GR[java.util.UUID]): GR[SessionRow] = GR{
    prs => import prs._
    SessionRow.tupled((<<[java.util.UUID], <<[java.util.UUID]))
  }
  /** Table description of table session. Objects of this class serve as prototypes for rows in queries. */
  class Session(_tableTag: Tag) extends profile.api.Table[SessionRow](_tableTag, "session") {
    def * = (id, userId) <> (SessionRow.tupled, SessionRow.unapply)
    /** Maps whole row to an option. Useful for outer joins. */
    def ? = ((Rep.Some(id), Rep.Some(userId))).shaped.<>({r=>import r._; _1.map(_=> SessionRow.tupled((_1.get, _2.get)))}, (_:Any) =>  throw new Exception("Inserting into ? projection not supported."))

    /** Database column id SqlType(uuid), PrimaryKey */
    val id: Rep[java.util.UUID] = column[java.util.UUID]("id", O.PrimaryKey)
    /** Database column user_id SqlType(uuid) */
    val userId: Rep[java.util.UUID] = column[java.util.UUID]("user_id")

    /** Foreign key referencing User (database name session_user_id_fk) */
    lazy val userFk = foreignKey("session_user_id_fk", userId, User)(r => r.id, onUpdate=ForeignKeyAction.NoAction, onDelete=ForeignKeyAction.Cascade)
  }
  /** Collection-like TableQuery object for table Session */
  lazy val Session = new TableQuery(tag => new Session(tag))

  /** Entity class storing rows of table User
   *  @param id Database column id SqlType(uuid), PrimaryKey
   *  @param nickname Database column nickname SqlType(text)
   *  @param displayName Database column display_name SqlType(text), Default(None)
   *  @param email Database column email SqlType(text)
   *  @param salt Database column salt SqlType(text)
   *  @param hash Database column hash SqlType(text) */
  case class UserRow(id: java.util.UUID, nickname: String, displayName: Option[String] = None, email: String, salt: String, hash: String)
  /** GetResult implicit for fetching UserRow objects using plain SQL queries */
  implicit def GetResultUserRow(implicit e0: GR[java.util.UUID], e1: GR[String], e2: GR[Option[String]]): GR[UserRow] = GR{
    prs => import prs._
    UserRow.tupled((<<[java.util.UUID], <<[String], <<?[String], <<[String], <<[String], <<[String]))
  }
  /** Table description of table user. Objects of this class serve as prototypes for rows in queries. */
  class User(_tableTag: Tag) extends profile.api.Table[UserRow](_tableTag, "user") {
    def * = (id, nickname, displayName, email, salt, hash) <> (UserRow.tupled, UserRow.unapply)
    /** Maps whole row to an option. Useful for outer joins. */
    def ? = ((Rep.Some(id), Rep.Some(nickname), displayName, Rep.Some(email), Rep.Some(salt), Rep.Some(hash))).shaped.<>({r=>import r._; _1.map(_=> UserRow.tupled((_1.get, _2.get, _3, _4.get, _5.get, _6.get)))}, (_:Any) =>  throw new Exception("Inserting into ? projection not supported."))

    /** Database column id SqlType(uuid), PrimaryKey */
    val id: Rep[java.util.UUID] = column[java.util.UUID]("id", O.PrimaryKey)
    /** Database column nickname SqlType(text) */
    val nickname: Rep[String] = column[String]("nickname")
    /** Database column display_name SqlType(text), Default(None) */
    val displayName: Rep[Option[String]] = column[Option[String]]("display_name", O.Default(None))
    /** Database column email SqlType(text) */
    val email: Rep[String] = column[String]("email")
    /** Database column salt SqlType(text) */
    val salt: Rep[String] = column[String]("salt")
    /** Database column hash SqlType(text) */
    val hash: Rep[String] = column[String]("hash")

    /** Uniqueness Index over (nickname) (database name user_nickname_key) */
    val index1 = index("user_nickname_key", nickname, unique=true)
  }
  /** Collection-like TableQuery object for table User */
  lazy val User = new TableQuery(tag => new User(tag))

  /** Entity class storing rows of table YieldAmount
   *  @param foodId Database column food_id SqlType(int4)
   *  @param yieldId Database column yield_id SqlType(int4)
   *  @param yieldAmount Database column yield_amount SqlType(int4)
   *  @param yieldDateOfEntry Database column yield_date_of_entry SqlType(date) */
  case class YieldAmountRow(foodId: Int, yieldId: Int, yieldAmount: Int, yieldDateOfEntry: java.sql.Date)
  /** GetResult implicit for fetching YieldAmountRow objects using plain SQL queries */
  implicit def GetResultYieldAmountRow(implicit e0: GR[Int], e1: GR[java.sql.Date]): GR[YieldAmountRow] = GR{
    prs => import prs._
    YieldAmountRow.tupled((<<[Int], <<[Int], <<[Int], <<[java.sql.Date]))
  }
  /** Table description of table yield_amount. Objects of this class serve as prototypes for rows in queries. */
  class YieldAmount(_tableTag: Tag) extends profile.api.Table[YieldAmountRow](_tableTag, Some("cnf"), "yield_amount") {
    def * = (foodId, yieldId, yieldAmount, yieldDateOfEntry) <> (YieldAmountRow.tupled, YieldAmountRow.unapply)
    /** Maps whole row to an option. Useful for outer joins. */
    def ? = ((Rep.Some(foodId), Rep.Some(yieldId), Rep.Some(yieldAmount), Rep.Some(yieldDateOfEntry))).shaped.<>({r=>import r._; _1.map(_=> YieldAmountRow.tupled((_1.get, _2.get, _3.get, _4.get)))}, (_:Any) =>  throw new Exception("Inserting into ? projection not supported."))

    /** Database column food_id SqlType(int4) */
    val foodId: Rep[Int] = column[Int]("food_id")
    /** Database column yield_id SqlType(int4) */
    val yieldId: Rep[Int] = column[Int]("yield_id")
    /** Database column yield_amount SqlType(int4) */
    val yieldAmount: Rep[Int] = column[Int]("yield_amount")
    /** Database column yield_date_of_entry SqlType(date) */
    val yieldDateOfEntry: Rep[java.sql.Date] = column[java.sql.Date]("yield_date_of_entry")

    /** Primary key of YieldAmount (database name yield_amount_pk) */
    val pk = primaryKey("yield_amount_pk", (foodId, yieldId))

    /** Foreign key referencing YieldName (database name yield_amount_yield_id_fk) */
    lazy val yieldNameFk = foreignKey("yield_amount_yield_id_fk", yieldId, YieldName)(r => r.yieldId, onUpdate=ForeignKeyAction.NoAction, onDelete=ForeignKeyAction.NoAction)
  }
  /** Collection-like TableQuery object for table YieldAmount */
  lazy val YieldAmount = new TableQuery(tag => new YieldAmount(tag))

  /** Entity class storing rows of table YieldName
   *  @param yieldId Database column yield_id SqlType(int4), PrimaryKey
   *  @param yieldDescription Database column yield_description SqlType(text)
   *  @param yieldDescriptionF Database column yield_description_f SqlType(text) */
  case class YieldNameRow(yieldId: Int, yieldDescription: String, yieldDescriptionF: String)
  /** GetResult implicit for fetching YieldNameRow objects using plain SQL queries */
  implicit def GetResultYieldNameRow(implicit e0: GR[Int], e1: GR[String]): GR[YieldNameRow] = GR{
    prs => import prs._
    YieldNameRow.tupled((<<[Int], <<[String], <<[String]))
  }
  /** Table description of table yield_name. Objects of this class serve as prototypes for rows in queries. */
  class YieldName(_tableTag: Tag) extends profile.api.Table[YieldNameRow](_tableTag, Some("cnf"), "yield_name") {
    def * = (yieldId, yieldDescription, yieldDescriptionF) <> (YieldNameRow.tupled, YieldNameRow.unapply)
    /** Maps whole row to an option. Useful for outer joins. */
    def ? = ((Rep.Some(yieldId), Rep.Some(yieldDescription), Rep.Some(yieldDescriptionF))).shaped.<>({r=>import r._; _1.map(_=> YieldNameRow.tupled((_1.get, _2.get, _3.get)))}, (_:Any) =>  throw new Exception("Inserting into ? projection not supported."))

    /** Database column yield_id SqlType(int4), PrimaryKey */
    val yieldId: Rep[Int] = column[Int]("yield_id", O.PrimaryKey)
    /** Database column yield_description SqlType(text) */
    val yieldDescription: Rep[String] = column[String]("yield_description")
    /** Database column yield_description_f SqlType(text) */
    val yieldDescriptionF: Rep[String] = column[String]("yield_description_f")
  }
  /** Collection-like TableQuery object for table YieldName */
  lazy val YieldName = new TableQuery(tag => new YieldName(tag))
}
