module Pages.Deletion.Completion.Page exposing (..)

import Configuration exposing (Configuration)


type alias Model =
    { configuration : Configuration
    }


type alias Flags =
    { configuration : Configuration
    }

type alias Msg = {}