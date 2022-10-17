module Pages.UserSettings.Page exposing (..)

import Api.Types.Mode exposing (Mode)
import Api.Types.User exposing (User)
import Http exposing (Error)
import Monocle.Lens exposing (Lens)
import Pages.UserSettings.Status exposing (Status)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.ComplementInput exposing (ComplementInput)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , user : User
    , complementInput : ComplementInput
    , initialization : Initialization Status
    , mode : Mode
    }


lenses :
    { user : Lens Model User
    , complementInput : Lens Model ComplementInput
    , initialization : Lens Model (Initialization Status)
    , mode : Lens Model Mode
    }
lenses =
    { user = Lens .user (\b a -> { a | user = b })
    , complementInput = Lens .complementInput (\b a -> { a | complementInput = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    , mode = Lens .mode (\b a -> { a | mode = b })
    }


type Mode
    = Regular
    | RequestedDeletion


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type Msg
    = GotFetchUserResponse (Result Error User)
    | UpdatePassword
    | GotUpdatePasswordResponse (Result Error ())
    | UpdateSettings
    | GotUpdateSettingsResponse (Result Error User)
    | RequestDeletion
    | GotRequestDeletionResponse (Result Error ())
    | SetComplementInput ComplementInput
    | Logout Api.Types.Mode.Mode
    | GotLogoutResponse (Result Error ())
