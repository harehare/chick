port module BackGroundSubscriptions exposing (..)

import BackGroundModel exposing (..)
import Model


port getQuery : (String -> msg) -> Sub msg


port queryResult : List String -> Cmd msg


port createItem : (Item -> msg) -> Sub msg


port getErrorItems : (Int -> msg) -> Sub msg


port errorItems : List Item -> Cmd msg


port indexItem : IndexData -> Cmd msg


port indexError : Int -> Cmd msg


port setSearchResult : List Model.Item -> Cmd msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ createItem OnCreateItem
        , getErrorItems OnErrorItems
        , getQuery OnGetQuery
        ]
