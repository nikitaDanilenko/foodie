module Pages.Util.ValidatedInput exposing
    ( ValidatedInput
    , isValid
    , lenses
    , lift
    , nonEmptyString
    , positive
    )

import Basics.Extra exposing (flip)
import Maybe.Extra
import Monocle.Lens exposing (Lens)


type alias ValidatedInput a =
    { value : a
    , ifEmptyValue : a
    , text : String
    , parse : String -> Result String a
    , partial : String -> Bool
    }


lenses :
    { text : Lens (ValidatedInput a) String
    , value : Lens (ValidatedInput a) a
    }
lenses =
    { text =
        Lens .text (\b a -> { a | text = b })
    , value =
        Lens .value (\b a -> { a | value = b })
    }


isValid : ValidatedInput a -> Bool
isValid validatedInput =
    case validatedInput.parse validatedInput.text of
        Ok v ->
            v == validatedInput.value

        Err _ ->
            False


setWithLens : Lens model (ValidatedInput a) -> String -> model -> model
setWithLens lens txt model =
    let
        validatedInput =
            lens.get model

        possiblyValid =
            if String.isEmpty txt || validatedInput.partial txt then
                validatedInput
                    |> lenses.text.set txt

            else
                validatedInput
    in
    case validatedInput.parse txt of
        Ok v ->
            possiblyValid
                |> lenses.value.set v
                |> flip lens.set model

        Err _ ->
            lens.set possiblyValid model


lift : Lens model (ValidatedInput a) -> Lens model String
lift lens =
    Lens (lens.get >> .text) (setWithLens lens)


positive : ValidatedInput Float
positive =
    { value = 1
    , ifEmptyValue = 1
    , text = "1"
    , parse =
        String.toFloat
            >> Maybe.Extra.filter (\x -> x > 0)
            >> Result.fromMaybe "Error"
    , partial = \str -> List.length (String.split "." str) <= 2 && String.all (\c -> c == '.' || Char.isDigit c) str
    }


nonEmptyString : ValidatedInput String
nonEmptyString =
    { value = ""
    , ifEmptyValue = ""
    , text = ""
    , parse =
        Just
            >> Maybe.Extra.filter (String.isEmpty >> not)
            >> Result.fromMaybe "Error: Empty string"
    , partial = always True
    }
