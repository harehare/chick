module PopupUpdate exposing (..)

import PopupModel exposing (..)
import PopupSubscriptions exposing (..)
import Json.Decode as Decode


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        ShowOption ->
            model ! [ showOption 0 ]

        EditSearchQuery query ->
            { model | query = query } ! []

        DoSearch ->
            model ! [ openSearchPage model.query ]

        SuspendResume ->
            let
                status =
                    not model.suspend
            in
                { model | suspend = status } ! [ suspend status ]


isEnter : Msg -> number -> Decode.Decoder Msg
isEnter msg code =
    if code == 13 then
        Decode.succeed msg
    else
        Decode.fail "not Enter"
