module Pages.Util.Style exposing (..)

import Html exposing (Attribute)
import Html.Attributes exposing (class)


classes :
    { addElement : Attribute msg
    , addView : Attribute msg
    , button :
        { add : Attribute msg
        , cancel : Attribute msg
        , confirm : Attribute msg
        , delete : Attribute msg
        , edit : Attribute msg
        , editor : Attribute msg
        , select : Attribute msg
        }
    , choices : Attribute msg
    , choiceTable : Attribute msg
    , controlsGroup : Attribute msg
    , controls : Attribute msg
    , date : Attribute msg
    , descriptionColumn : Attribute msg
    , editable : Attribute msg
    , editing : Attribute msg
    , editLine : Attribute msg
    , elements : Attribute msg
    , info : Attribute msg
    , numberCell : Attribute msg
    , numberLabel : Attribute msg
    , tableHeader : Attribute msg
    , time : Attribute msg
    }
classes =
    { addElement = class "addElement"
    , addView = class "addView"
    , button =
        { add = class "addButton"
        , cancel = class "cancelButton.cancel"
        , confirm = class "confirmButton"
        , delete = class "button.delete"
        , edit = class "button.edit"
        , editor = class "button.editor"
        , select = class "button.select"
        }
    , choices = class "choices"
    , choiceTable = class "choiceTable"
    , controlsGroup = class "controlsGroup"
    , controls = class "controls"
    , date = class "date"
    , descriptionColumn = class "descriptionColumn"
    , editable = class "editable"
    , editing = class "editing"
    , editLine = class "editLine"
    , elements = class "elements"
    , info = class "info"
    , numberCell = class "numberCell"
    , numberLabel = class "numberLabel"
    , tableHeader = class "tableHeader"
    , time = class "time"
    }
