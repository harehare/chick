port module Option exposing (..)

import OptionModel exposing (..)
import OptionSubscriptions exposing (..)
import OptionUpdate exposing (..)
import OptionView exposing (..)
import Html exposing (..)


-- ENTRY POINT


init : Model -> ( Model, Cmd Msg )
init model =
    model ! [ doSearch model.query ]


main : Program Model Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
