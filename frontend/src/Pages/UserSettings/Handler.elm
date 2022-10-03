module Pages.UserSettings.Handler exposing (init, update)

import Maybe.Extra
import Pages.UserSettings.Page as Page
import Ports


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    let
        ( jwt, cmd ) =
            flags.jwt
                |> Maybe.Extra.unwrap
                    ( "", Ports.doFetchToken () )
                    (\token ->
                        ( token
                        , Requests.fetchUser
                            { configuration = flags.configuration
                            , jwt = token
                            }
                        )
                    )
    in
    ( { flagsWithJWT =
            { configuration = flags.configuration
            , jwt = jwt
            },
        user = {}
      }
    , cmd
    )
