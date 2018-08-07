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
            { style =
                Animation.style
                    [ Animation.opacity 0.0
                    ]
            , visible = True
            , top = 130
            , right = 10
            , query = ""
            , items = []
            }
                ! []
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
