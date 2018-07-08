module PopupModel exposing (..)


type Msg
    = NoOp
    | Index IndexStatus
    | AddIndex Int
    | AddIndexComplate Int
    | ShowOption
    | SuspendResume


type alias Model =
    { status : IndexStatus
    , suspend : Bool
    }


type alias IndexStatus =
    { documentCount : Int
    , indexedCount : Int
    }
