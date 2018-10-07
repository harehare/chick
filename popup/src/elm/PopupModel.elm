module PopupModel exposing (Model, Msg(..))

import Model exposing (Item)


type Msg
    = NoOp
    | ShowOption
    | EditSearchQuery String
    | DoSearch
    | TagClick String
    | SuspendResume
    | GetSimilarPages (List Item)


type alias Model =
    { suspend : Bool
    , query : String
    , tags : List String
    , items : List Item
    }
