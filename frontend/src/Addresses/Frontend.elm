module Addresses.Frontend exposing (AddressWithParser, ingredientEditor, login, mealEntryEditor, meals, overview, recipes, referenceNutrients, requestRecovery, requestRegistration, statistics, userSettings)

import Api.Auxiliary exposing (MealId, RecipeId)
import Pages.Util.ParserUtil as ParserUtil
import Url.Parser exposing ((</>), Parser, s)


type alias AddressWithParser a i o =
    { address : a -> List String
    , parser : Parser i o
    }


requestRegistration : AddressWithParser () a a
requestRegistration =
    plain "request-registration"


requestRecovery : AddressWithParser () a a
requestRecovery =
    plain "request-recovery"


overview : AddressWithParser () a a
overview =
    plain "overview"


mealEntryEditor : AddressWithParser MealId (MealId -> a) a
mealEntryEditor =
    with1
        { prefix = "meal-entry-editor"
        , toString = identity
        , paramParser = ParserUtil.uuidParser
        }


recipes : AddressWithParser () a a
recipes =
    plain "recipes"


meals : AddressWithParser () a a
meals =
    plain "meals"


statistics : AddressWithParser () a a
statistics =
    plain "statistics"


referenceNutrients : AddressWithParser () a a
referenceNutrients =
    plain "reference-nutrients"


userSettings : AddressWithParser () a a
userSettings =
    plain "user-settings"


ingredientEditor : AddressWithParser RecipeId (RecipeId -> a) a
ingredientEditor =
    with1
        { prefix = "ingredient-editor"
        , toString = identity
        , paramParser = ParserUtil.uuidParser
        }


login : AddressWithParser () a a
login =
    plain "login"


plain : String -> AddressWithParser () a a
plain string =
    { address = always [ string ]
    , parser = s string
    }


with1 :
    { prefix : String
    , toString : param -> String
    , paramParser : Parser (param -> a) a
    }
    -> AddressWithParser param (param -> a) a
with1 ps =
    { address = \param -> [ ps.prefix, ps.toString param ]
    , parser = s ps.prefix </> ps.paramParser
    }
