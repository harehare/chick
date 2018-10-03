module PopupModel exposing (Model, Msg(..))


type Msg
    = NoOp
    | ShowOption
    | EditSearchQuery String
    | DoSearch
    | TagClick String
    | SuspendResume


type alias Model =
    { suspend : Bool
    , query : String
    , tags : List String
    }
