port module Popup exposing (..)

import PopupModel exposing (..)
import PopupSubscriptions exposing (..)
import PopupUpdate exposing (..)
import PopupView exposing (..)
import Html exposing (..)


-- ENTRY POINT


init : Model -> ( Model, Cmd Msg )
init model =
    ( model, Cmd.none )


main : Program Model Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
