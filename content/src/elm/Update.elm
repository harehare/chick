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

        SearchApi req ->
            model ! [ requestSearchApi (Tuple.first req) (Tuple.second req) SearchApiResult ]

        SearchApiResult (Err err) ->
            model ! []

        SearchApiResult (Ok items) ->
            { model | items = items } ! []

        SearchResult params ->
            let
                query =
                    Tuple.first params

                items =
                    Tuple.second params
                        |> List.filter (\x -> x.title /= "")
            in
                { model | query = query, items = items } ! []


decodeSearchApiResponse : Decode.Decoder Item
decodeSearchApiResponse =
    Decode.map6 Item
        (Decode.field "url" Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "snippet" Decode.string)
        (Decode.field "itemType" Decode.string)
        (Decode.field "bookmark" Decode.bool)
        (Decode.field "tags" (Decode.list Decode.string))


requestSearchApi : String -> String -> (Result Http.Error (List Item) -> a) -> Cmd a
requestSearchApi url q msg =
    Http.send msg
        (Http.get
            (url
                ++ "/search?q="
                ++ q
            )
            (Decode.list decodeSearchApiResponse)
        )
