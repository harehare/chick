module Model exposing (..)

import Http
import Animation


type Msg
    = NoOp
    | TokenizeNGram String
    | CloseSearchResult
    | SearchResult ( String, List Item )
    | QueryParse ( String, String )
    | SetPosition ( Int, Int )
    | QueryParseResult (Result Http.Error (List String))
    | Scoring ScoringApiRequest
    | ScoreResult (Result Http.Error (List Score))
    | Show Int
    | Close
    | Animate Animation.Msg


type alias Model =
    { items : List Item
    , visible : Bool
    , top : Int
    , right : Int
    , query : String
    , style : Animation.State
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
