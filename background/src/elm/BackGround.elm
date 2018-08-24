port module BackGround exposing (..)

import BackGroundModel exposing (..)
import BackGroundSubscriptions exposing (..)
import Http
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
            { model | items = insert item.url item model.items }
                ! [ Http.send IndexItem
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


main : Program Never Model Msg
main =
    Platform.program
        { init =
            ( { items =
                    fromList
                        [ ( "", { url = "", title = "", lastVisitTime = Nothing, itemType = "" } )
                        ]
              }
            , Cmd.none
            )
        , update = update
        , subscriptions = subscriptions
        }
