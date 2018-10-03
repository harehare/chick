port module Popup exposing (init, main)

import Dom
import Html exposing (..)
import List exposing (..)
import PopupModel exposing (..)
import PopupSubscriptions exposing (..)
import PopupUpdate exposing (..)
import PopupView exposing (..)
import Task exposing (..)



-- ENTRY POINT


init : Model -> ( Model, Cmd Msg )
init model =
    ( { model | tags = List.sort model.tags }, Task.attempt (\_ -> NoOp) <| Dom.focus "search-query" )


main : Program Model Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
