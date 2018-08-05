module BackGroundModel exposing (..)

import Http
import Dict exposing (Dict)


type Msg
    = NoOp
    | OnCreateItem Item
    | OnCreateItemWithApi ( String, List Item )
    | OnGetQuery String
    | IndexItem (Result Http.Error ResponseItem)
    | IndexItems (Result Http.Error (List ApiResponseItem))
    | OnErrorItems Int


type alias Model =
    { items : Dict String Item }


type alias IndexData =
    { words : List String
    , snippet : String
    , url : String
    , title : String
    , lastVisitTime : Maybe Int
    , itemType : String
    }


type alias Item =
    { title : String
    , url : String
    , lastVisitTime : Maybe Int
    , itemType : String
    }


type alias ResponseItem =
    { url : String
    , body : String
    }


type alias ApiResponseItem =
    { url : String
    , tokens : List String
    , snippet : String
    , statusCode : Int
    }
