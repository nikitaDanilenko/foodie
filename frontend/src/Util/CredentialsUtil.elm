module Util.CredentialsUtil exposing (..)

import Api.Types.Credentials exposing (Credentials)
import Monocle.Lens exposing (Lens)


nickname : Lens Credentials String
nickname =
    Lens .nickname (\b a -> { a | nickname = b })


password : Lens Credentials String
password =
    Lens .password (\b a -> { a | password = b })
