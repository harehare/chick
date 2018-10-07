module OptionUpdate exposing (..)

import Time
import Process
import Task
import Dom
import String exposing (isEmpty)
import List exposing (..)
import List.Extra exposing (unique, find, remove)
import OptionModel exposing (..)
import OptionSubscriptions exposing (..)
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

                pocket =
                    if target == "pocket" then
                        not model.indexTarget.pocket
                    else
                        model.indexTarget.pocket
            in
                { model
                    | changed = True
                    , indexTarget = { bookmark = bookmark, history = history, pocket = pocket }
                }
                    ! []

        Save ->
            { model | changed = False } ! [ saveSettings model ]

        Reindexing ->
            { model | isIndexing = True } ! [ reindexing 0 ]

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
                                    -- TODO:
                                    { url = x.url
                                    , title = x.title
                                    , snippet = x.snippet
                                    , itemType = x.itemType
                                    , bookmark = info.bookmark
                                    , tags = info.tags
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

        DataImport ->
            model ! [ dataImport model.indexTarget ]

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

        InputTag index ->
            let
                i =
                    find (\x -> index.url == x.url) model.indexInfo

                indexInfo =
                    case i of
                        Just xs ->
                            { xs | tags = xs.tags ++ index.tags |> unique, isInputting = not xs.isInputting }

                        Nothing ->
                            { index | isInputting = True }
            in
                { model
                    | inputTag = ""
                    , indexInfo =
                        case i of
                            Just xs ->
                                List.map
                                    (\x ->
                                        if x.url == index.url then
                                            indexInfo
                                        else
                                            { x | isInputting = False }
                                    )
                                    model.indexInfo

                            Nothing ->
                                indexInfo :: (List.map (\i -> { i | isInputting = False }) model.indexInfo)
                }
                    ! [ Task.attempt (\_ -> NoOp) <| Dom.focus index.url ]

        EditTag tag ->
            { model | inputTag = tag } ! []

        AddTag index ->
            let
                i =
                    find (\x -> index.url == x.url) model.indexInfo

                indexInfo =
                    case i of
                        Just xs ->
                            { xs | tags = model.inputTag :: xs.tags |> unique, isInputting = False }

                        Nothing ->
                            { index | tags = [ model.inputTag ], isInputting = False }
            in
                { model
                    | changed = True
                    , inputTag = ""
                    , tags = indexInfo.tags ++ model.tags |> unique
                    , indexInfo =
                        case i of
                            Just xs ->
                                List.map
                                    (\x ->
                                        if x.url == index.url then
                                            indexInfo
                                        else
                                            index
                                    )
                                    model.indexInfo

                            Nothing ->
                                indexInfo :: model.indexInfo
                }
                    ! []

        ChangeTag checked url tag ->
            let
                index =
                    find (\x -> url == x.url) model.indexInfo

                resultItem =
                    find (\x -> url == x.url) model.searchResult
            in
                { model
                    | changed = True
                    , inputTag = ""
                    , indexInfo =
                        case index of
                            Just xs ->
                                List.map
                                    (\item ->
                                        if item.url == url then
                                            { item
                                                | tags =
                                                    if checked then
                                                        remove tag item.tags
                                                    else
                                                        tag
                                                            :: item.tags
                                                            |> unique
                                            }
                                        else
                                            item
                                    )
                                    model.indexInfo

                            Nothing ->
                                case resultItem of
                                    Just xs ->
                                        { url = xs.url
                                        , bookmark = xs.bookmark
                                        , tags =
                                            if checked then
                                                remove tag xs.tags
                                            else
                                                tag
                                                    :: xs.tags
                                                    |> unique
                                        , isInputting = False
                                        }
                                            :: model.indexInfo

                                    Nothing ->
                                        model.indexInfo
                }
                    ! []

        SearchTag tag ->
            { model | query = model.query ++ " #" ++ tag } ! [ doSearch (model.query ++ " #" ++ tag) ]
