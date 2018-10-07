module BackGroundModel exposing (..)

import Http
import Dict exposing (Dict)
import Model


type Msg
    = NoOp
    | OnCreateItem Item
    | OnGetQuery String
    | IndexItem (Result Http.Error ResponseItem)
    | OnErrorItems Int


type alias Model =
    { items : Dict String Item
    }


type alias IndexData =
    { words : List String
    , snippet : String
    , url : String
    , title : String
    , createdAt : Maybe Int
    , itemType : String
    }


type alias Item =
    { title : String
    , url : String
    , createdAt : Maybe Int
    , itemType : String
    }


type alias ResponseItem =
    { url : String
    , body : String
    }
