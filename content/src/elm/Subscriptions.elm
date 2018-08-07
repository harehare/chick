port module Subscriptions exposing (..)

import Time exposing (millisecond)
import Model exposing (..)
import Animation


port tokenizeNGram : (String -> msg) -> Sub msg


port tokenizeResult : List String -> Cmd msg


port searchResult : (( String, List Item ) -> msg) -> Sub msg


port queryParse : (( String, String ) -> msg) -> Sub msg


port queryParseResult : List String -> Cmd msg


port scoring : (ScoringApiRequest -> msg) -> Sub msg


port setPosition : (( Int, Int ) -> msg) -> Sub msg


port show : (Int -> msg) -> Sub msg


port scoreResult : List Score -> Cmd msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ tokenizeNGram TokenizeNGram
        , show Show
        , searchResult SearchResult
        , queryParse QueryParse
        , scoring Scoring
        , setPosition SetPosition
        , Animation.subscription Animate [ model.style ]
        ]
