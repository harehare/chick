port module PopupSubscriptions exposing (..)

import PopupModel exposing (..)


port addIndex : (Int -> msg) -> Sub msg


port addIndexComplate : (Int -> msg) -> Sub msg


port showOption : Int -> Cmd msg


port suspend : Bool -> Cmd msg


port openSearchPage : String -> Cmd msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        []
