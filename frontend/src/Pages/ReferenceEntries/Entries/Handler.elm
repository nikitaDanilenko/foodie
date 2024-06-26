module Pages.ReferenceEntries.Entries.Handler exposing (..)

import Api.Auxiliary exposing (ReferenceMapId)
import Api.Types.Nutrient exposing (encoderNutrient)
import Json.Encode as Encode
import Pages.ReferenceEntries.Entries.Page as Page
import Pages.ReferenceEntries.Entries.Requests as Requests
import Pages.ReferenceEntries.ReferenceEntryCreationClientInput as ReferenceEntryCreationClientInput
import Pages.ReferenceEntries.ReferenceEntryUpdateClientInput as ReferenceEntryUpdateClientInput
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Choice.Handler
import Ports


initialFetch : AuthorizedAccess -> ReferenceMapId -> Cmd Page.LogicMsg
initialFetch authorizedAccess referenceMapId =
    Cmd.batch
        [ Requests.fetchReferenceEntries authorizedAccess referenceMapId
        , Ports.doFetchNutrients ()
        ]


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic =
    Pages.Util.Choice.Handler.updateLogic
        { idOfElement = .nutrientCode
        , idOfChoice = .code
        , choiceIdOfElement = .nutrientCode
        , choiceIdOfCreation = .nutrientCode
        , toUpdate = ReferenceEntryUpdateClientInput.from
        , toCreation = \nutrient -> ReferenceEntryCreationClientInput.default nutrient.code
        , createElement = \authorizedAccess referenceMapId creation -> ReferenceEntryCreationClientInput.toCreation creation |> Requests.createReferenceEntry authorizedAccess referenceMapId
        , saveElement =
            \authorizedAccess referenceMapId nutrientCode update ->
                ReferenceEntryUpdateClientInput.to update
                    |> Requests.saveReferenceEntry authorizedAccess referenceMapId nutrientCode
        , deleteElement = Requests.deleteReferenceEntry
        , storeChoices =
            Encode.list encoderNutrient
                >> Encode.encode 0
                >> Ports.storeNutrients
        }
