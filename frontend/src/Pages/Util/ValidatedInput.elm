module Pages.Util.ValidatedInput exposing
    ( FromInput
    , emptyText
    , isValid
    , lift
    , text
    , value
    )

import Basics.Extra exposing (flip)
import Monocle.Lens exposing (Lens)


type alias FromInput a =
    { value : a
    , ifEmptyValue : a
    , text : String
    , parse : String -> Result String a
    , partial : String -> Bool
    }


text : Lens (FromInput a) String
text =
    Lens .text (\b a -> { a | text = b })


value : Lens (FromInput a) a
value =
    Lens .value (\b a -> { a | value = b })


emptyText :
    { ifEmptyValue : a
    , value : a
    , parse : String -> Result String a
    , isPartial : String -> Bool
    }
    -> FromInput a
emptyText params =
    { value = params.value
    , ifEmptyValue = params.ifEmptyValue
    , text = ""
    , parse = params.parse
    , partial = params.isPartial
    }


isValid : FromInput a -> Bool
isValid fromInput =
    case fromInput.parse fromInput.text of
        Ok v ->
            v == fromInput.value

        Err _ ->
            False


setWithLens : Lens model (FromInput a) -> String -> model -> model
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


lift : Lens model (FromInput a) -> Lens model String
lift lens =
    Lens (lens.get >> .text) (setWithLens lens)
