port module PopupSubscriptions exposing (..)

import PopupModel exposing (..)


port index : (IndexStatus -> msg) -> Sub msg


port addIndex : (Int -> msg) -> Sub msg


port addIndexComplate : (Int -> msg) -> Sub msg


port showOption : Int -> Cmd msg


port suspend : Bool -> Cmd msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ index Index
        , addIndex AddIndex
        , addIndexComplate AddIndexComplate
        ]
