port module OptionSubscriptions exposing (..)

import OptionModel exposing (..)


port saveSettings : Model -> Cmd msg


port reindexing : Int -> Cmd msg


port deleteIndex : Int -> Cmd msg


port selectText : String -> Cmd msg


port succeedVerify : String -> Cmd msg


port failedVerify : String -> Cmd msg


subscriptions model =
    Sub.batch
        []
