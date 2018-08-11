port module OptionSubscriptions exposing (..)

import OptionModel exposing (..)
import PopupModel exposing (IndexStatus)
import Model exposing (Item)
import Subscriptions exposing (tokenizeNGram)


port updateStatus : (IndexStatus -> msg) -> Sub msg


port optionSearchResult : (List Item -> msg) -> Sub msg


port saveSettings : Model -> Cmd msg


port reindexing : Int -> Cmd msg


port deleteIndex : Int -> Cmd msg


port selectText : String -> Cmd msg


port succeedVerify : String -> Cmd msg


port failedVerify : String -> Cmd msg


port importPocket : Int -> Cmd msg


port doSearch : String -> Cmd msg


subscriptions model =
    Sub.batch
        [ updateStatus UpdateStatus
        , tokenizeNGram OptionTokenizeNGram
        , optionSearchResult OptionSearchResult
        ]
