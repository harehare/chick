port module Subscriptions exposing (..)

import Model exposing (..)


port tokenizeNGram : (String -> msg) -> Sub msg


port tokenizeResult : List String -> Cmd msg


port searchResult : (( String, List Item ) -> msg) -> Sub msg


port queryParse : (( String, String ) -> msg) -> Sub msg


port queryParseResult : List String -> Cmd msg


port imageUrl : (String -> msg) -> Sub msg


port scoring : (ScoringApiRequest -> msg) -> Sub msg


port changeVisiblety : (Bool -> msg) -> Sub msg


port scoreResult : List Score -> Cmd msg


port setVisiblety : Bool -> Cmd msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ tokenizeNGram TokenizeNGram
        , searchResult SearchResult
        , queryParse QueryParse
        , scoring Scoring
        , imageUrl ImageUrl
        , changeVisiblety ChangeVisiblety
        ]
