module Pages.LoginTest.LoginTest exposing (..)

import Addresses.Frontend
import Api.Types.Credentials exposing (Credentials)
import Fuzz exposing (Fuzzer, string)
import Html exposing (Html)
import Html.Attributes
import Pages.Login.Page
import Pages.Login.View
import Pages.Util.EventUtil as EventUtil
import Pages.Util.Links as Links
import Pages.Util.Style as Style
import Test exposing (..)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector exposing (attribute, tag)


credentials : Credentials
credentials =
    { nickname = ""
    , password = ""
    }


mainModel : Pages.Login.Page.Main
mainModel =
    { credentials = credentials
    }


view : Html Pages.Login.Page.LogicMsg
view =
    Pages.Login.View.viewMain mainModel


inputs : Test
inputs =
    describe "login"
        [ fuzz string "set nickname" <|
            \nickname ->
                view
                    |> Query.fromHtml
                    |> Query.findAll [ tag "div", tag "input" ]
                    |> Query.index 0
                    |> Event.simulate (Event.input nickname)
                    |> Event.expect (Pages.Login.Page.SetNickname nickname)
        , fuzz string "set password" <|
            \password ->
                view
                    |> Query.fromHtml
                    |> Query.findAll [ tag "div", tag "input" ]
                    |> Query.index 1
                    |> Event.simulate (Event.input password)
                    |> Event.expect (Pages.Login.Page.SetPassword password)
        ]


onEnterShortcut : Test
onEnterShortcut =
    test "Pressing enter in input" <|
        \_ ->
            view
                |> Query.fromHtml
                |> Query.findAll [ tag "div", tag "input" ]
                |> Query.each (Event.simulate EventUtil.enter >> Event.expect Pages.Login.Page.Login)


onLoginClick : Test
onLoginClick =
    test "Clicking 'Log In'" <|
        \_ ->
            view
                |> Query.fromHtml
                |> Query.find [ attribute Style.classes.button.confirm ]
                |> Event.simulate Event.click
                |> Event.expect Pages.Login.Page.Login


registrationLink : Test
registrationLink =
    test "Registration link is correct" <|
        \_ ->
            view
                |> Query.fromHtml
                |> Query.findAll [ attribute Style.classes.button.navigation ]
                |> Query.index 0
                |> Query.has
                    [ attribute <|
                        Html.Attributes.href <|
                            Links.frontendPage <|
                                Addresses.Frontend.requestRegistration.address <|
                                    ()
                    ]


recoveryLink : Test
recoveryLink =
    test "Recovery link is correct" <|
        \_ ->
            view
                |> Query.fromHtml
                |> Query.findAll [ attribute Style.classes.button.navigation ]
                |> Query.index 1
                |> Query.has
                    [ attribute <|
                        Html.Attributes.href <|
                            Links.frontendPage <|
                                Addresses.Frontend.requestRecovery.address <|
                                    ()
                    ]
