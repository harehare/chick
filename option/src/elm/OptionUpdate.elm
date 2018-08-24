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
            { model | changed = False } ! [ saveSettings model ]

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

        SelectText id ->
            model ! [ selectText id ]

        Import ->
            model ! [ importIndex 0 ]
