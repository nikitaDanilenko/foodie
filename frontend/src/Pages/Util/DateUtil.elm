module Pages.Util.DateUtil exposing (dateParser, dateToString, timeParser, timeToString, toString)

import Api.Types.Date exposing (Date)
import Api.Types.SimpleDate exposing (SimpleDate)
import Api.Types.Time exposing (Time)
import Maybe.Extra
import Parser exposing ((|.), (|=), Parser)


toString : SimpleDate -> String
toString simpleDate =
    [ simpleDate.date |> dateToString
    , simpleDate.time |> Maybe.Extra.unwrap "" timeToString
    ]
        |> String.join " "
        |> String.trim


dateToString : Date -> String
dateToString date =
    [ date.year
    , date.month
    , date.day
    ]
        |> List.map padToTwo
        |> String.join "-"


padToTwo : Int -> String
padToTwo i =
    if i >= 0 && i <= 9 then
        String.concat [ "0", String.fromInt i ]

    else
        String.fromInt i


timeToString : Time -> String
timeToString time =
    [ time.hour, time.minute ]
        |> List.map padToTwo
        |> String.join ":"



-- todo: Add validation


dateParser : Parser Date
dateParser =
    Parser.succeed Date
        |= intWithOptionalLeadingZero
        |. Parser.symbol "-"
        |= intWithOptionalLeadingZero
        |. Parser.symbol "-"
        |= intWithOptionalLeadingZero


intWithOptionalLeadingZero : Parser Int
intWithOptionalLeadingZero =
    Parser.oneOf
        [ Parser.symbol "0" |> Parser.andThen (always Parser.int)
        , Parser.int
        ]



-- todo: Add validation


timeParser : Parser Time
timeParser =
    Parser.succeed Time
        |= intWithOptionalLeadingZero
        |. Parser.symbol ":"
        |= intWithOptionalLeadingZero
