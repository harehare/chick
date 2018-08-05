module Model exposing (..)

import Http


type Msg
    = NoOp
    | CloseSearchResult
    | TokenizeNGram String
    | SearchResult ( String, List Item )
    | QueryParse ( String, String )
    | QueryParseResult (Result Http.Error (List String))
    | Scoring ScoringApiRequest
    | ScoreResult (Result Http.Error (List Score))


type alias Model =
    { items : List Item
    , visible : Bool
    , top : Int
    , right : Int
    , query : String
    }


type alias Item =
    { url : String
    , title : String
    , snippet : String
    , itemType : String
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
