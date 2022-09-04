port module Ports exposing
    ( doFetchFoods
    , doFetchMeasures
    , doFetchToken
    , fetchFoods
    , fetchMeasures
    , fetchToken
    , storeFoods
    , storeMeasures
    , storeToken
    )


port storeToken : String -> Cmd msg


port doFetchToken : () -> Cmd msg


port fetchToken : (String -> msg) -> Sub msg


port storeFoods : String -> Cmd msg


port doFetchFoods : () -> Cmd msg


port fetchFoods : (String -> msg) -> Sub msg


port storeMeasures : String -> Cmd msg


port doFetchMeasures : () -> Cmd msg


port fetchMeasures : (String -> msg) -> Sub msg
