port module OptionSubscriptions exposing (..)

import OptionModel exposing (..)
import PopupModel exposing (IndexStatus)


port updateStatus : (IndexStatus -> msg) -> Sub msg


port saveSettings : Model -> Cmd msg


port reindexing : Int -> Cmd msg


port deleteIndex : Int -> Cmd msg


port selectText : String -> Cmd msg


port succeedVerify : String -> Cmd msg


port failedVerify : String -> Cmd msg


port importPocket : Int -> Cmd msg


subscriptions model =
    Sub.batch
        [ updateStatus UpdateStatus ]
