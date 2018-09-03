port module BackGround exposing (..)

import BackGroundModel exposing (..)
import BackGroundSubscriptions exposing (..)
import Http
import Json.Encode as Encode
import Regex exposing (find, replace, HowMany, regex, caseInsensitive)
import Json.Decode as Decode
import Time
import String.Extra exposing (stripTags)
import String exposing (lines, length, trim, split, left, join)
import List exposing (head, filter, map, concat, append)
import List.Extra exposing (unique)
import Dict exposing (Dict, get, insert, remove, fromList, toList, values)
import NGram exposing (tokeinze)
import Normalize
import Stopwords


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        OnCreateItem item ->
            { model | items = insert item.url item model.items } ! [ fetchUrlInfo item IndexItem ]

        OnCreateItemFromApi items ->
            let
                url =
                    Tuple.first items

                item =
                    Tuple.second items
            in
                { model | searchApiUrl = url ++ "/index", items = insert item.url item model.items } ! [ fetchUrlInfo item IndexItemFromApi ]

        IndexCompleted (Err err) ->
            model ! [ indexError 1 ]

        IndexCompleted (Ok data) ->
            -- TODO:
            model ! []

        IndexItemFromApi (Err err) ->
            model ! [ indexError 1 ]

        IndexItemFromApi (Ok data) ->
            let
                item =
                    case get data.url model.items of
                        Just xs ->
                            xs

                        Nothing ->
                            { url = "", title = "", lastVisitTime = Nothing, itemType = "" }

                title =
                    getTitle data.body
            in
                model
                    ! [ requestIndexApi model.searchApiUrl
                            { title =
                                case title of
                                    Just xs ->
                                        xs

                                    Nothing ->
                                        item.title
                            , url = item.url
                            , body =
                                data.body
                                    |> removeHtmlTag
                                    |> stripTags
                                    |> removeUnnecessary
                            , itemType = item.itemType
                            }
                      ]

        IndexItem (Err err) ->
            model ! [ indexError 1 ]

        IndexItem (Ok data) ->
            let
                item =
                    case get data.url model.items of
                        Just xs ->
                            xs

                        Nothing ->
                            { url = "", title = "", lastVisitTime = Nothing, itemType = "" }

                title =
                    getTitle data.body

                text =
                    data.body
                        |> removeHtmlTag
                        |> stripTags
                        |> removeUnnecessary
                        |> left 5000

                words =
                    text
                        |> Normalize.normalize
                        |> lines
                        |> filter (\x -> (trim x) /= "")
                        |> map (\x -> map (\xx -> tokeinze xx) (split " " x) |> concat)
                        |> concat
                        |> unique
            in
                { model | items = remove item.url model.items }
                    ! [ indexItem
                            { words = words
                            , snippet = left 200 text
                            , url = item.url
                            , title =
                                case title of
                                    Just xs ->
                                        xs

                                    Nothing ->
                                        item.title
                            , lastVisitTime = item.lastVisitTime
                            , itemType = item.itemType
                            }
                      ]

        OnErrorItems _ ->
            model ! [ errorItems (values model.items) ]

        OnGetQuery text ->
            model ! [ queryResult (tokeinze text) ]


readHtml : Http.Response String -> Result String ResponseItem
readHtml response =
    Ok ({ url = response.url, body = response.body })


getTitle : String -> Maybe String
getTitle text =
    let
        match =
            text
                |> replace Regex.All (regex "\n") (\_ -> "")
                |> find (Regex.AtMost 1) (regex "<title[^>]*?>([^<]+)</title>")
                |> head

        result =
            case match of
                Just xs ->
                    xs.submatches

                Nothing ->
                    []
    in
        case head result of
            Just xs ->
                xs

            Nothing ->
                Nothing


removeHtmlTag : String -> String
removeHtmlTag text =
    text
        |> replace Regex.All (regex "<meta[^>]*?>[\\s\\S]*?</meta>") (\_ -> "")
        |> replace Regex.All (regex "<script[^>]*?>[\\s\\S]*?</script>") (\_ -> "")
        |> replace Regex.All (regex "<style[^>]*?>[\\s\\S]*?</style>") (\_ -> "")
        |> replace Regex.All (regex "\"[^\"]*\"") (\_ -> "")
        |> replace Regex.All (regex "'[^']*'") (\_ -> "")


removeUnnecessary : String -> String
removeUnnecessary text =
    text
        |> replace Regex.All (regex " +") (\_ -> " ")
        |> replace Regex.All (regex "\n|\t|\x0D|&quot;") (\_ -> " ")
        |> replace Regex.All (regex Stopwords.words |> caseInsensitive) (\_ -> "")


decodeIndexApiResponse : Decode.Decoder IndexApiResponse
decodeIndexApiResponse =
    Decode.map IndexApiResponse
        (Decode.field "count" Decode.int)


encodeIndexApiRequest : IndexApiItem -> List Encode.Value
encodeIndexApiRequest item =
    [ Encode.object
        [ ( "title", Encode.string item.title )
        , ( "url", Encode.string item.url )
        , ( "body", Encode.string item.body )
        , ( "itemType", Encode.string item.itemType )
        ]
    ]


requestIndexApi : String -> IndexApiItem -> Cmd Msg
requestIndexApi url item =
    Http.send IndexCompleted
        (Http.post url
            (item
                |> encodeIndexApiRequest
                |> Encode.list
                |> Http.jsonBody
            )
            decodeIndexApiResponse
        )


fetchUrlInfo : Item -> (Result Http.Error ResponseItem -> a) -> Cmd a
fetchUrlInfo item msg =
    Http.send msg
        (Http.request
            { method = "GET"
            , headers = []
            , url = item.url
            , body = Http.emptyBody
            , expect = Http.expectStringResponse readHtml
            , timeout = Just (3 * Time.second)
            , withCredentials = False
            }
        )


main : Program Never Model Msg
main =
    Platform.program
        { init =
            ( { items =
                    fromList
                        [ ( "", { url = "", title = "", lastVisitTime = Nothing, itemType = "" } )
                        ]
              , searchApiUrl = ""
              }
            , Cmd.none
            )
        , update = update
        , subscriptions = subscriptions
        }
