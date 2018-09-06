module PopupModel exposing (..)


type Msg
    = NoOp
    | ShowOption
    | EditSearchQuery String
    | DoSearch
    | SuspendResume


type alias Model =
    { suspend : Bool
    , query : String
    }
