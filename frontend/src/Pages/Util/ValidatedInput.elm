module Pages.Util.ValidatedInput exposing
    ( ValidatedInput
    , emptyText
    , isValid
    , lift
    , text
    , value
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


text : Lens (ValidatedInput a) String
text =
    Lens .text (\b a -> { a | text = b })


value : Lens (ValidatedInput a) a
value =
    Lens .value (\b a -> { a | value = b })


emptyText :
    { ifEmptyValue : a
    , value : a
    , parse : String -> Result String a
    , isPartial : String -> Bool
    }
    -> ValidatedInput a
emptyText params =
    { value = params.value
    , ifEmptyValue = params.ifEmptyValue
    , text = ""
    , parse = params.parse
    , partial = params.isPartial
    }


isValid : ValidatedInput a -> Bool
isValid fromInput =
    case fromInput.parse fromInput.text of
        Ok v ->
            v == fromInput.value

        Err _ ->
            False


setWithLens : Lens model (ValidatedInput a) -> String -> model -> model
setWithLens lens txt model =
    let
        fromInput =
            lens.get model

        possiblyValid =
            if String.isEmpty txt || fromInput.partial txt then
                fromInput
                    |> text.set txt

            else
                fromInput
    in
    case fromInput.parse txt of
        Ok v ->
            possiblyValid
                |> value.set v
                |> flip lens.set model

        Err _ ->
            lens.set possiblyValid model


lift : Lens model (ValidatedInput a) -> Lens model String
lift lens =
    Lens (lens.get >> .text) (setWithLens lens)


positive : ValidatedInput Float
positive =
    { value = 0
    , ifEmptyValue = 0
    , text = ""
    , parse =
        String.toFloat
            >> Maybe.Extra.filter (\x -> x > 0)
            >> Result.fromMaybe "Error"
    , partial = \str -> List.length (String.split "." str) <= 2 && String.all (\c -> c == '.' || Char.isDigit c) str
    }
