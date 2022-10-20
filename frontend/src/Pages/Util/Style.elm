module Pages.Util.Style exposing (..)

import Html exposing (Attribute)
import Html.Attributes exposing (class, id)


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
        , logout : Attribute msg
        , navigation : Attribute msg
        , pager: Attribute msg
        , select : Attribute msg
        }
    , choices : Attribute msg
    , choiceTable : Attribute msg
    , confirm : Attribute msg
    , controlsGroup : Attribute msg
    , controls : Attribute msg
    , date : Attribute msg
    , descriptionColumn : Attribute msg
    , disabled : Attribute msg
    , editable : Attribute msg
    , editing : Attribute msg
    , editLine : Attribute msg
    , elements : Attribute msg
    , ellipsis : Attribute msg
    , info : Attribute msg
    , intervalSelection : Attribute msg
    , meals : Attribute msg
    , numberCell : Attribute msg
    , numberLabel : Attribute msg
    , nutrients : Attribute msg
    , pagination : Attribute msg
    , rating :
        { low : Attribute msg
        , exact : Attribute msg
        , high : Attribute msg
        }
    , request : Attribute msg
    , search :
        { area : Attribute msg
        , field : Attribute msg
        }
    , tableHeader : Attribute msg
    , time : Attribute msg
    }
classes =
    { addElement = class "addElement"
    , addView = class "addView"
    , button =
        { add = class "addButton"
        , cancel = class "cancelButton"
        , confirm = class "confirmButton"
        , delete = class "deleteButton"
        , edit = class "editButton"
        , editor = class "editorButton"
        , logout = class "logoutButton"
        , navigation = class "navigationButton"
        , pager = class "pagerButton"
        , select = class "selectButton"
        }
    , choices = class "choices"
    , choiceTable = class "choiceTable"
    , confirm = class "confirm"
    , controlsGroup = class "controlsGroup"
    , controls = class "controls"
    , date = class "date"
    , descriptionColumn = class "descriptionColumn"
    , disabled = class "disabled"
    , editable = class "editable"
    , editing = class "editing"
    , editLine = class "editLine"
    , elements = class "elements"
    , ellipsis = class "ellipsis"
    , info = class "info"
    , intervalSelection = class "intervalSection"
    , meals = class "meals"
    , numberCell = class "numberCell"
    , numberLabel = class "numberLabel"
    , nutrients = class "nutrients"
    , pagination = class "pagination"
    , rating =
        { low = class "low"
        , exact = class "exact"
        , high = class "high"
        }
        , request = class "request"
    , search =
        { area = class "searchArea"
        , field = class "searchField"
        }
    , tableHeader = class "tableHeader"
    , time = class "time"
    }


ids :
    { add : Attribute msg
    , addMealView : Attribute msg
    , addRecipeView : Attribute msg
    , addReferenceMapView : Attribute msg
    , error : Attribute msg
    , ingredientEditor : Attribute msg
    , mealEntryEditor : Attribute msg
    , mealsButton : Attribute msg
    , navigation : Attribute msg
    , overviewMain : Attribute msg
    , recipesButton : Attribute msg
    , referenceEntryEditor : Attribute msg
    , referenceMapsButton : Attribute msg
    , statistics : Attribute msg
    , statisticsButton : Attribute msg
    , userSettingsButton : Attribute msg
    }
ids =
    { add = id "add"
    , addMealView = id "addMealView"
    , addRecipeView = id "addRecipeView"
    , addReferenceMapView = id "addReferenceMapView"
    , error = id "error"
    , ingredientEditor = id "ingredientEditor"
    , mealEntryEditor = id "mealEntryEditor"
    , mealsButton = id "mealsButton"
    , navigation = id "navigation"
    , overviewMain = id "overviewMain"
    , recipesButton = id "recipesButton"
    , referenceEntryEditor = id "referenceEntryEditor"
    , referenceMapsButton = id "referenceMapsButton"
    , statistics = id "statistics"
    , statisticsButton = id "statisticsButton"
    , userSettingsButton = id "userSettingsButton"
    }
