module Pages.Util.ParserUtil exposing (AddressWithParser, nicknameEmailParser, uuidParser, with1, with2)

import Api.Types.UUID exposing (UUID)
import List.Extra
import Url.Parser as Parser exposing ((</>), Parser, s)


uuidParser : Parser (UUID -> b) b
uuidParser =
    Parser.custom "UUID" matchUuid


nicknameEmailParser : AddressWithParser ( String, String ) (String -> String -> a) a
nicknameEmailParser =
    with2
        { step1 = "nickname"
        , toString1 = List.singleton
        , step2 = "email"
        , toString2 = List.singleton
        , paramParser1 = Parser.string
        , paramParser2 = Parser.string
        }


type alias AddressWithParser a i o =
    { address : a -> List String
    , parser : Parser i o
    }


with1 :
    { step1 : String
    , toString : param -> List String
    , paramParser : Parser a b
    }
    -> AddressWithParser param a b
with1 ps =
    { address = \param -> ps.step1 :: ps.toString param
    , parser = s ps.step1 </> ps.paramParser
    }


with2 :
    { step1 : String
    , toString1 : b -> List String
    , step2 : String
    , toString2 : c -> List String
    , paramParser1 : Parser a1 a2
    , paramParser2 : Parser a2 a3
    }
    -> AddressWithParser ( b, c ) a1 a3
with2 ps =
    { address =
        \( param1, param2 ) ->
            List.singleton ps.step1
                ++ ps.toString1 param1
                ++ List.singleton ps.step2
                ++ ps.toString2 param2
    , parser =
        s ps.step1
            </> ps.paramParser1
            </> s ps.step2
            </> ps.paramParser2
    }



-- todo: Version 4 UUID have restrictions on two positions - implement these


matchUuid : String -> Maybe UUID
matchUuid str =
    let
        gs =
            splitAt '-' (String.toList str)

        groupsCorrect =
            -- UUID format
            List.map List.length gs == [ 8, 4, 4, 4, 12 ]

        symbolsCorrect =
            -- UUID character set
            List.all Char.isHexDigit (List.concat gs)
    in
    if groupsCorrect && symbolsCorrect then
        Just str

    else
        Nothing



-- todo: Move splitAt to a more sensible position


splitAt : a -> List a -> List (List a)
splitAt sep xs =
    case xs of
        [] ->
            []

        l ->
            let
                ( start, end ) =
                    List.Extra.break ((==) sep) l
            in
            start :: splitAt sep (List.drop 1 end)
