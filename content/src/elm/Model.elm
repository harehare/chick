module Model exposing (..)

import Http


type Msg
    = NoOp
    | TokenizeNGram String
    | SearchResult ( String, List Item )
    | ToggleSearchResult
    | ImageUrl String
    | ChangeVisiblety Bool
    | SearchApi ( String, String )
    | SearchApiResult (Result Http.Error (List Item))


type alias Model =
    { items : List Item
    , visible : Bool
    , query : String
    , imageUrl : String
    }


type alias Item =
    { url : String
    , title : String
    , snippet : String
    , itemType : String
    , bookmark : Bool
    }
