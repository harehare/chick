module PopupUpdate exposing (isEnter, update)

import Json.Decode as Decode
import PopupModel exposing (..)
import PopupSubscriptions exposing (..)


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

        TagClick tag ->
            { model | query = model.query ++ " #" ++ tag } ! []


isEnter : Msg -> number -> Decode.Decoder Msg
isEnter msg code =
    if code == 13 then
        Decode.succeed msg

    else
        Decode.fail "not Enter"
