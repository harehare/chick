port module Subscriptions exposing (..)

import Model exposing (..)


port tokenizeNGram : (String -> msg) -> Sub msg


port tokenizeResult : List String -> Cmd msg


port searchResult : (( String, List Item ) -> msg) -> Sub msg


port imageUrl : (String -> msg) -> Sub msg


port changeVisiblety : (Bool -> msg) -> Sub msg


port search : (( String, String ) -> msg) -> Sub msg


port setVisiblety : Bool -> Cmd msg


port openOption : Int -> Cmd msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ tokenizeNGram TokenizeNGram
        , searchResult SearchResult
        , imageUrl ImageUrl
        , changeVisiblety ChangeVisiblety
        , search SearchApi
        ]
