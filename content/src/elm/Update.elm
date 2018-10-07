module Update exposing (..)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Model exposing (..)
import NGram exposing (tokeinze)
import List
import Subscriptions exposing (..)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        TokenizeNGram text ->
            model ! [ tokenizeResult (tokeinze text) ]

        ToggleSearchResult ->
            { model | visible = not model.visible } ! [ setVisiblety (not model.visible) ]

        ImageUrl url ->
            { model | imageUrl = url } ! []

        ChangeVisiblety visible ->
            { model | visible = visible } ! []

        OpenOption ->
            model ! [ openOption 0 ]

        SearchResult params ->
            let
                query =
                    Tuple.first params

                items =
                    Tuple.second params
                        |> List.filter (\x -> x.title /= "")
            in
                { model | query = query, items = items } ! []
