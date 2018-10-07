port module PopupSubscriptions exposing (..)

import PopupModel exposing (..)
import Model exposing (Item)


port addIndex : (Int -> msg) -> Sub msg


port addIndexComplate : (Int -> msg) -> Sub msg


port showOption : Int -> Cmd msg


port suspend : Bool -> Cmd msg


port openSearchPage : String -> Cmd msg


port simi : String -> Cmd msg


port similarPages : (List Item -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ similarPages GetSimilarPages ]
