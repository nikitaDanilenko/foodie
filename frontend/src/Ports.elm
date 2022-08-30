port module Ports exposing (storeToken, fetchToken, doFetchToken)

port storeToken : String -> Cmd msg
port doFetchToken : () -> Cmd msg
port fetchToken : (String -> msg) -> Sub msg
