module Pages.Overview.Handler exposing (init, update)

import Api.Auxiliary exposing (JWT)
import Browser.Navigation as Navigation
import Maybe.Extra
import Pages.Overview.Page as Page
import Pages.Overview.Status as Status
import Ports
import Url.Builder as UrlBuilder
import Util.Initialization as Initialization
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    let
        ( jwt, cmd ) =
            flags.jwt
                |> Maybe.Extra.unwrap ( "", Ports.doFetchToken () )
                    (\token -> ( token, Cmd.none ))
    in
    ( { flagsWithJWT =
            { configuration = flags.configuration
            , jwt = jwt
            }
      , initialization = Initialization.Loading (Status.initial |> Status.lenses.jwt.set (jwt |> String.isEmpty |> not))
      }
    , cmd
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.UpdateJWT jwt ->
            updateJWT model jwt

        Page.Recipes ->
            navigate model "recipes"

        Page.Meals ->
            navigate model "meals"

        Page.Statistics ->
            navigate model "statistics"

        Page.ReferenceNutrients ->
            navigate model "reference-nutrients"


updateJWT : Page.Model -> JWT -> ( Page.Model, Cmd Page.Msg )
updateJWT model jwt =
    ( model
        |> Page.lenses.jwt.set jwt
        |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.jwt).set True
    , Cmd.none
    )


navigate : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
navigate model subFolder =
    ( model
    , Navigation.load <|
        UrlBuilder.relative
            [ model.flagsWithJWT.configuration.mainPageURL
            , "#"
            , subFolder
            ]
            []
    )
