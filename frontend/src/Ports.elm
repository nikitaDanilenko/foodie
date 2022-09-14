port module Ports exposing
    ( doFetchFoods
    , doFetchMeasures
    , doFetchNutrients
    , doFetchToken
    , fetchFoods
    , fetchMeasures
    , fetchNutrients
    , fetchToken
    , storeFoods
    , storeMeasures
    , storeNutrients
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


port storeNutrients : String -> Cmd msg


port doFetchNutrients : () -> Cmd msg


port fetchNutrients : (String -> msg) -> Sub msg
