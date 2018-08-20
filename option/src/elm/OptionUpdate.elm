module OptionUpdate exposing (..)

import Time
import Process
import Regex
import Task
import List exposing (..)
import String exposing (toInt)
import List.Extra exposing (unique, find)
import OptionModel exposing (..)
import OptionSubscriptions exposing (..)
import PopupModel exposing (IndexStatus)
import BackGround exposing (requestScrapingApi)
import Update exposing (requestQueryParseApi, requestScoringApi)
import Subscriptions exposing (tokenizeResult)
import NGram exposing (tokeinze)


delay : Time.Time -> msg -> Cmd msg
delay time msg =
    Process.sleep time
        |> Task.perform (\_ -> msg)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        EditBlockKeyword keyword ->
            { model | changed = True, blockKeyword = keyword } ! []

        DeleteBlockKeyword keyword ->
            { model | changed = True, blockList = model.blockList |> List.filter (\x -> x /= keyword) } ! []

        AddBlockList ->
            { model | changed = True, blockKeyword = "", blockList = model.blockKeyword :: model.blockList |> unique } ! []

        ChangeViewOption service ->
            let
                google =
                    if service == "google" then
                        not model.viewOption.google
                    else
                        model.viewOption.google

                bing =
                    if service == "bing" then
                        not model.viewOption.bing
                    else
                        model.viewOption.bing

                duckDuckGo =
                    if service == "duckduckgo" then
                        not model.viewOption.duckDuckGo
                    else
                        model.viewOption.duckDuckGo

                yahoo =
                    if service == "yahoo" then
                        not model.viewOption.yahoo
                    else
                        model.viewOption.yahoo
            in
                { model
                    | changed = True
                    , viewOption = { google = google, bing = bing, duckDuckGo = duckDuckGo, yahoo = yahoo }
                }
                    ! []

        ChangeIndexTarget target ->
            let
                bookmark =
                    if target == "bookmark" then
                        not model.indexTarget.bookmark
                    else
                        model.indexTarget.bookmark

                history =
                    if target == "history" then
                        not model.indexTarget.history
                    else
                        model.indexTarget.history
            in
                { model
                    | changed = True
                    , indexTarget = { bookmark = bookmark, history = history }
                }
                    ! []

        Save ->
            let
                advanced =
                    (if model.advancedOption.scrapingApi.url == "" then
                        updateVerifyStatus Scraping model.advancedOption model.advancedOption.scrapingApi False
                     else
                        model.advancedOption
                    )
                        |> (\x ->
                                if x.queryParseApi.url == "" then
                                    updateVerifyStatus QueryParse x x.queryParseApi False
                                else
                                    x
                           )
                        |> (\x ->
                                if x.scoringApi.url == "" then
                                    updateVerifyStatus Scoring x x.scoringApi False
                                else
                                    x
                           )
            in
                { model | changed = False, advancedOption = advanced } ! [ saveSettings model ]

        Reindexing ->
            { model | isIndexing = True } ! [ reindexing 0 ]

        DeleteIndex ->
            model ! [ deleteIndex 0 ]

        Bookmark info ->
            let
                index =
                    find (\x -> info.url == x.url) model.indexInfo
            in
                { model
                    | changed = True
                    , searchResult =
                        map
                            (\x ->
                                if x.url == info.url then
                                    { url = x.url
                                    , title = x.title
                                    , snippet = x.snippet
                                    , itemType = x.itemType
                                    , bookmark = info.bookmark
                                    }
                                else
                                    x
                            )
                            model.searchResult
                    , indexInfo =
                        case index of
                            Just xs ->
                                map
                                    (\x ->
                                        if x.url == xs.url then
                                            xs
                                        else
                                            x
                                    )
                                    model.indexInfo

                            Nothing ->
                                info :: model.indexInfo
                }
                    ! []

        Export ->
            model ! [ export 0 ]

        DeleteItem url ->
            { model
                | deleteUrlList = url :: model.deleteUrlList
                , searchResult = List.filter (\x -> url /= x.url) model.searchResult
                , changed = True
            }
                ! []

        ImportPocket ->
            model ! [ importPocket 0 ]

        UpdateStatus status ->
            { model | status = status } ! []

        OptionTokenizeNGram text ->
            model ! [ tokenizeResult (tokeinze text) ]

        EditSearchQuery query ->
            { model | query = query } ! [ doSearch query ]

        OptionSearchResult searchResult ->
            { model | searchResult = searchResult } ! []

        EditApiUrl api url ->
            let
                scrapingApi =
                    if api == Scraping then
                        url
                    else
                        model.advancedOption.scrapingApi.url

                queryParseApi =
                    if api == QueryParse then
                        url
                    else
                        model.advancedOption.queryParseApi.url

                scoringApi =
                    if api == Scoring then
                        url
                    else
                        model.advancedOption.scoringApi.url
            in
                { model
                    | changed = True
                    , advancedOption =
                        { scrapingApi =
                            { url = scrapingApi
                            , verify =
                                if scrapingApi == "" then
                                    False
                                else
                                    model.advancedOption.scrapingApi.verify
                            }
                        , queryParseApi =
                            { url = queryParseApi
                            , verify =
                                if queryParseApi == "" then
                                    False
                                else
                                    model.advancedOption.queryParseApi.verify
                            }
                        , scoringApi =
                            { url = scoringApi
                            , verify =
                                if scoringApi == "" then
                                    False
                                else
                                    model.advancedOption.scoringApi.verify
                            }
                        }
                }
                    ! []

        SelectText id ->
            model ! [ selectText id ]

        VerifyScrapingApi ->
            model ! [ requestScrapingApi model.advancedOption.scrapingApi.url [ "http://example.com/" ] ResponseScrapingApi ]

        VerifyQueryParseApi ->
            model ! [ requestQueryParseApi model.advancedOption.queryParseApi.url "test" ResponseQueryParseApi ]

        VerifyScoringApi ->
            model
                ! [ requestScoringApi
                        { apiUrl = model.advancedOption.scoringApi.url
                        , urls = [ "http://example.com/" ]
                        , tokens = [ "example" ]
                        }
                        ResponseScoringApi
                  ]

        ResponseScrapingApi (Err _) ->
            { model | advancedOption = (updateVerifyStatus Scraping model.advancedOption model.advancedOption.scrapingApi False) }
                ! [ failedVerify "Scraping API" ]

        ResponseScrapingApi (Ok result) ->
            { model | changed = True, advancedOption = (updateVerifyStatus Scraping model.advancedOption model.advancedOption.scrapingApi True) }
                ! [ succeedVerify "Scraping API" ]

        ResponseQueryParseApi (Err _) ->
            { model | advancedOption = (updateVerifyStatus QueryParse model.advancedOption model.advancedOption.queryParseApi False) }
                ! [ failedVerify "Query Parse API" ]

        ResponseQueryParseApi (Ok result) ->
            { model | changed = True, advancedOption = (updateVerifyStatus QueryParse model.advancedOption model.advancedOption.queryParseApi True) }
                ! [ succeedVerify "Query Parse API" ]

        ResponseScoringApi (Err _) ->
            { model | advancedOption = (updateVerifyStatus Scoring model.advancedOption model.advancedOption.scoringApi False) }
                ! [ failedVerify "Scoring API" ]

        ResponseScoringApi (Ok result) ->
            { model | changed = True, advancedOption = (updateVerifyStatus Scoring model.advancedOption model.advancedOption.scoringApi True) }
                ! [ succeedVerify "Scoring API" ]


updateVerifyStatus : Api -> Advanced -> ApiStatus -> Bool -> Advanced
updateVerifyStatus apiType option api verify =
    let
        result =
            { api | verify = verify }
    in
        case apiType of
            Scraping ->
                { option | scrapingApi = result }

            QueryParse ->
                { option | queryParseApi = result }

            Scoring ->
                { option | scoringApi = result }
