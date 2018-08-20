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

        SearchResult params ->
            let
                query =
                    Tuple.first params

                items =
                    Tuple.second params
                        |> List.filter (\x -> x.title /= "")
            in
                { model | query = query, items = items } ! []

        QueryParse params ->
            let
                url =
                    Tuple.first params

                q =
                    Tuple.second params
            in
                model ! [ requestQueryParseApi url q QueryParseResult ]

        QueryParseResult (Err err) ->
            model ! []

        QueryParseResult (Ok tokens) ->
            model ! [ queryParseResult tokens ]

        Scoring params ->
            model ! [ requestScoringApi params ScoreResult ]

        ScoreResult (Err err) ->
            model ! []

        ScoreResult (Ok tokens) ->
            model ! [ scoreResult tokens ]


requestQueryParseApi : String -> String -> (Result Http.Error (List String) -> a) -> Cmd a
requestQueryParseApi apiUrl q msg =
    Http.send msg (Http.get (apiUrl ++ "?q=" ++ (Http.encodeUri q)) (Decode.list Decode.string))


decodeScoringApiResponse : Decode.Decoder Score
decodeScoringApiResponse =
    Decode.map3 Score
        (Decode.field "word" Decode.string)
        (Decode.field "url" Decode.string)
        (Decode.field "score" Decode.float)


requestScoringApi : ScoringApiRequest -> (Result Http.Error (List Score) -> a) -> Cmd a
requestScoringApi req msg =
    Http.send msg
        (Http.post req.apiUrl
            ([ ( "tokens", (Encode.list <| List.map Encode.string <| req.tokens) )
             , ( "urls", (Encode.list <| List.map Encode.string <| req.urls) )
             ]
                |> Encode.object
                |> Http.jsonBody
            )
            (Decode.list decodeScoringApiResponse)
        )
