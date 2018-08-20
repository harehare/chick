port module Main exposing (..)

import Model exposing (..)
import Subscriptions exposing (..)
import Update exposing (..)
import View exposing (..)
import Html exposing (..)
import Animation


-- ENTRY POINT


main : Program Never Model Msg
main =
    Html.program
        { init =
            { visible = True
            , query = ""
            , items = []
            , imageUrl = ""
            }
                ! []
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
