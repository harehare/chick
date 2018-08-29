module BackGroundModel exposing (..)

import Http
import Dict exposing (Dict)


type Msg
    = NoOp
    | OnCreateItem Item
    | OnCreateItemFromApi ( String, Item )
    | OnGetQuery String
    | IndexItem (Result Http.Error ResponseItem)
    | IndexItemFromApi (Result Http.Error ResponseItem)
    | IndexCompleted (Result Http.Error IndexApiResponse)
    | OnErrorItems Int


type alias Model =
    { items : Dict String Item
    , searchApiUrl : String
    }


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


type alias IndexApiItem =
    { title : String
    , url : String
    , body : String
    , itemType : String
    }


type alias IndexApiResponse =
    { count : Int
    }
