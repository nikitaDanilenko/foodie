port module Ports exposing (doFetchFoods, doFetchToken, fetchFoods, fetchToken, storeFoods, storeToken)


port storeToken : String -> Cmd msg


port doFetchToken : () -> Cmd msg


port fetchToken : (String -> msg) -> Sub msg


port storeFoods : String -> Cmd msg


port doFetchFoods : () -> Cmd msg


port fetchFoods : (String -> msg) -> Sub msg
