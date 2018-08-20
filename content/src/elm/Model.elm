module Model exposing (..)

import Http


type Msg
    = NoOp
    | TokenizeNGram String
    | SearchResult ( String, List Item )
    | ToggleSearchResult
    | QueryParse ( String, String )
    | QueryParseResult (Result Http.Error (List String))
    | Scoring ScoringApiRequest
    | ScoreResult (Result Http.Error (List Score))
    | ImageUrl String
    | ChangeVisiblety Bool


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


type alias ScoringApiRequest =
    { apiUrl : String
    , tokens : List String
    , urls : List String
    }


type alias Score =
    { word : String
    , url : String
    , score : Float
    }
