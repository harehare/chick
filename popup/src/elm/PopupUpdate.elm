module PopupUpdate exposing (..)

import PopupModel exposing (..)
import PopupSubscriptions exposing (..)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        Index status ->
            { model | status = status } ! []

        AddIndex i ->
            { model
                | status =
                    { documentCount = model.status.documentCount + i
                    , indexedCount = model.status.indexedCount
                    }
            }
                ! []

        AddIndexComplate i ->
            { model
                | status =
                    { documentCount = model.status.documentCount
                    , indexedCount = model.status.indexedCount + i
                    }
            }
                ! []

        ShowOption ->
            model ! [ showOption 0 ]

        SuspendResume ->
            let
                status =
                    not model.suspend
            in
                { model | suspend = status } ! [ suspend status ]
