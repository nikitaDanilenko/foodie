module Addresses.Frontend exposing (confirmRecovery, confirmRegistration, deleteAccount, ingredientEditor, login, mealEntryEditor, meals, overview, recipes, referenceNutrients, requestRecovery, requestRegistration, statistics, userSettings)

import Api.Auxiliary exposing (MealId, RecipeId)
import Api.Types.UserIdentifier exposing (UserIdentifier)
import Pages.Util.ParserUtil as ParserUtil exposing (AddressWithParser, with1, with2)
import Url.Parser as Parser exposing ((</>), Parser, s)


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
        { step1 = "meal-entry-editor"
        , toString = List.singleton
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
        { step1 = "ingredient-editor"
        , toString = List.singleton
        , paramParser = ParserUtil.uuidParser
        }


login : AddressWithParser () a a
login =
    plain "login"


confirmRegistration : AddressWithParser ( ( String, String ), String ) (UserIdentifier -> String -> a) a
confirmRegistration =
    confirm "confirm-registration"


deleteAccount : AddressWithParser ( ( String, String ), String ) (UserIdentifier -> String -> a) a
deleteAccount =
    confirm "delete-account"


confirmRecovery : AddressWithParser ( ( String, String ), String ) (UserIdentifier -> String -> a) a
confirmRecovery =
    confirm "recover-account"


confirm : String -> AddressWithParser ( ( String, String ), String ) (UserIdentifier -> String -> a) a
confirm step1 =
    with2
        { step1 = step1
        , toString1 = ParserUtil.nicknameEmailParser.address
        , step2 = "token"
        , toString2 = List.singleton
        , paramParser1 = ParserUtil.nicknameEmailParser.parser |> Parser.map UserIdentifier
        , paramParser2 = Parser.string
        }


plain : String -> AddressWithParser () a a
plain string =
    { address = always [ string ]
    , parser = s string
    }
