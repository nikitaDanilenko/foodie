module Pages.UserSettings.Page exposing (..)

import Api.Auxiliary exposing (JWT)
import Api.Types.User exposing (User)
import Configuration exposing (Configuration)
import Http exposing (Error)
import Monocle.Lens exposing (Lens)
import Pages.Util.ComplementInput exposing (ComplementInput)
import Pages.Util.FlagsWithJWT exposing (FlagsWithJWT)


type alias Model =
    { flagsWithJWT : FlagsWithJWT
    , user : User
    , complementInput : ComplementInput
    }


lenses :
    { user : Lens Model User
    , complementInput : Lens Model ComplementInput
    }
lenses =
    { user = Lens .user (\b a -> { a | user = b })
    , complementInput = Lens .complementInput (\b a -> { a | complementInput = b })
    }


type alias Flags =
    { configuration : Configuration
    , jwt : Maybe String
    }


type Msg
    = UpdateJWT JWT
    | GotFetchUserResponse (Result Error User)
    | UpdatePassword
    | Update
    | RequestDeletion
