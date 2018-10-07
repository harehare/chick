module Model exposing (..)

import Http


type Msg
    = NoOp
    | TokenizeNGram String
    | SearchResult ( String, List Item )
    | ToggleSearchResult
    | ImageUrl String
    | ChangeVisiblety Bool
    | OpenOption


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
    , tags : List String
    }
