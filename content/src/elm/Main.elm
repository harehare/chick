port module Main exposing (..)

import Model exposing (..)
import Subscriptions exposing (..)
import Update exposing (..)
import View exposing (..)
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
