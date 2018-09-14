module BackGroundModel exposing (..)

import Http
import Dict exposing (Dict)
import Model


type Msg
    = NoOp
    | OnCreateItem Item
    | OnCreateItemFromApi ( String, Item )
    | OnGetQuery String
    | IndexItem (Result Http.Error ResponseItem)
    | IndexItemFromApi (Result Http.Error ResponseItem)
    | IndexCompleted (Result Http.Error IndexApiResponse)
    | IndexAll Int
    | OnErrorItems Int
    | BackgroundSearchApi ( String, String )
    | SearchApiResult (Result Http.Error (List Model.Item))


type alias Model =
    { items : Dict String Item
    , searchApiUrl : String
    , indexingItems : List IndexApiItem
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


type alias IndexApiItem =
    { title : String
    , url : String
    , body : String
    , itemType : String
    }


type alias IndexApiResponse =
    { count : Int
    }
