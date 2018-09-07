port module Popup exposing (..)

import PopupModel exposing (..)
import PopupSubscriptions exposing (..)
import PopupUpdate exposing (..)
import PopupView exposing (..)
import Html exposing (..)
import Task exposing (..)
import Dom


-- ENTRY POINT


init : Model -> ( Model, Cmd Msg )
init model =
    ( model, Task.attempt (\_ -> NoOp) <| Dom.focus "search-query" )


main : Program Model Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
