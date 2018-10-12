module OptionView exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (..)
import List exposing (filter, member, isEmpty)
import List.Extra exposing (uniqueBy, find, unique)
import String exposing (split)
import OptionModel exposing (..)
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Form.Input as Input
import Bootstrap.Button as Button
import Bootstrap.Badge as Badge
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.ListGroup as ListGroup
import Bootstrap.Utilities.Spacing as Spacing
import FontAwesome.Solid as SolidIcon
import FontAwesome.Brands as BrandsIcon
import FontAwesome.Regular as RegularIcon
import Bootstrap.Form as Form
import Bootstrap.Progress as Progress
import Model exposing (Item)
import Bootstrap.Alert as Alert
import Html.Events.Extra exposing (onEnter)


view : Model -> Html Msg
view model =
    div
        [ style
            [ ( "display", "flex" )
            , ( "flex-direction", "column" )
            , ( "width", "100vw" )
            , ( "height", "100%" )
            , ( "overflow-y", "scroll" )
            , ( "background-color", "#FEFEFE" )
            , ( "color", "#777" )
            , ( "font-family", "'Open Sans', sans-serif" )
            ]
        ]
        [ div
            [ style
                [ ( "background-color", "#FCFCFC" )
                , ( "min-height", "70px" )
                , ( "width", "100%" )
                , ( "border", "1px solid rgba(150,150,150,0.3)" )
                , ( "display", "flex" )
                , ( "align-items", "center" )
                ]
            ]
            [ lazy3 (searchResultList model.logoUrl model.query model.tags model.deleteUrlList) model.searchResult model.inputTag model.indexInfo
            ]
        , lazy2 dataImport model.status model.indexTarget
        , lazy viewOption model.viewOption
        , lazy2 blackUrlList model.blockKeyword model.blockList
        ]


viewOption : ViewOption -> Html Msg
viewOption option =
    div
        [ style
            [ ( "box-shadow", "0 2px 3px rgba(0,0,0,0.06)" )
            , ( "border", "1px solid rgba(150,150,150,0.3)" )
            , ( "padding", "1% 2%" )
            , ( "margin", "15px" )
            , ( "border-radius", "5px" )
            , ( "background-color", "#FEFEFE" )
            ]
        ]
        [ h5
            [ style
                [ ( "font-weight", "300" )
                ]
            ]
            [ text "SHOW RESULTS" ]
        , Checkbox.checkbox
            [ Checkbox.id "google", Checkbox.inline, Checkbox.checked option.google, Checkbox.attrs [ ChangeViewOption "google" |> onClick ] ]
            "Google"
        , Checkbox.checkbox
            [ Checkbox.id "bing", Checkbox.inline, Checkbox.checked option.bing, Checkbox.attrs [ ChangeViewOption "bing" |> onClick ] ]
            "Bing"
        , Checkbox.checkbox
            [ Checkbox.id "duckduckgo", Checkbox.inline, Checkbox.checked option.duckDuckGo, Checkbox.attrs [ ChangeViewOption "duckduckgo" |> onClick ] ]
            "DuckDuckGo"
        , Checkbox.checkbox
            [ Checkbox.id "yahoo", Checkbox.inline, Checkbox.checked option.yahoo, Checkbox.attrs [ ChangeViewOption "yahoo" |> onClick ] ]
            "Yahoo Japan"
        ]


dataImport : IndexStatus -> IndexTarget -> Html Msg
dataImport status option =
    let
        currentStatus =
            (toFloat status.indexedCount
                / toFloat
                    (if status.documentCount == 0 then
                        1
                     else
                        status.documentCount
                    )
            )
                * 100.0

        isIndexing =
            status.documentCount - status.indexedCount > 0

        message =
            ((toString status.indexedCount) ++ " items indexed complete")
    in
        div
            [ style
                [ ( "box-shadow", "0 2px 3px rgba(0,0,0,0.06)" )
                , ( "border", "1px solid rgba(150,150,150,0.3)" )
                , ( "padding", "1% 2%" )
                , ( "margin", "15px" )
                , ( "border-radius", "5px" )
                , ( "background-color", "#FEFEFE" )
                ]
            ]
            [ h5
                [ style
                    [ ( "font-weight", "300" )
                    , ( "margin-bottom", "10px" )
                    ]
                ]
                [ text "DATA IMPORT" ]
            , if isIndexing then
                Alert.simpleLight [] [ text message, Progress.progress [ Progress.info, Progress.value currentStatus ] ]
              else
                Alert.simplePrimary [] [ text message ]
            , div
                []
                [ Checkbox.checkbox
                    [ Checkbox.id "bookmark", Checkbox.inline, Checkbox.checked option.bookmark, Checkbox.attrs [ ChangeIndexTarget "bookmark" |> onClick ] ]
                    "Bookmark"
                , Checkbox.checkbox
                    [ Checkbox.id "history", Checkbox.inline, Checkbox.checked option.history, Checkbox.attrs [ ChangeIndexTarget "history" |> onClick ] ]
                    "History"
                , Checkbox.checkbox
                    [ Checkbox.id "pocket", Checkbox.inline, Checkbox.checked option.pocket, Checkbox.attrs [ ChangeIndexTarget "pocket" |> onClick ] ]
                    "Pocket"
                , div [ style [ ( "margin-top", "20px" ) ] ]
                    [ Button.button
                        [ Button.attrs [ style [ ( "margin-left", "5px" ), ( "height", "45px" ) ] ]
                        , Button.onClick DataImport
                        , Button.info
                        , Button.disabled isIndexing
                        ]
                        [ text "START IMPORT"
                        ]
                    , Button.button
                        [ Button.attrs [ style [ ( "margin-left", "5px" ), ( "height", "45px" ) ] ]
                        , Button.onClick Reindexing
                        , Button.info
                        , Button.disabled isIndexing
                        ]
                        [ div [ style [ ( "width", "15px" ) ] ] [ SolidIcon.sync_alt ]
                        ]
                    , Button.button
                        [ Button.attrs [ style [ ( "margin-left", "15px" ), ( "height", "45px" ) ] ]
                        , Button.onClick Import
                        , Button.info
                        , Button.disabled isIndexing
                        ]
                        [ text "IMPORT FILE"
                        ]
                    , Button.button
                        [ Button.attrs [ style [ ( "margin-left", "15px" ), ( "height", "45px" ) ] ]
                        , Button.onClick Export
                        , Button.info
                        , Button.disabled isIndexing
                        ]
                        [ text "EXPORT FILE"
                        ]
                    ]
                ]
            ]


blackUrlList : String -> List String -> Html Msg
blackUrlList keyword urlList =
    div
        [ style
            [ ( "box-shadow", "0 2px 3px rgba(0,0,0,0.06)" )
            , ( "border", "1px solid rgba(150,150,150,0.3)" )
            , ( "padding", "1% 2%" )
            , ( "margin", "15px" )
            , ( "border-radius", "5px" )
            , ( "background-color", "#FEFEFE" )
            ]
        ]
        [ h5
            [ style
                [ ( "font-family", "'Roboto', sans-serif" )
                , ( "font-weight", "300" )
                ]
            ]
            [ text "BLOCKING AND FILTERING" ]
        , InputGroup.config (InputGroup.text [ Input.placeholder "Enter URL or Keyword", Input.onInput EditBlockKeyword ])
            |> InputGroup.successors
                [ InputGroup.button
                    [ Button.secondary
                    , Button.disabled (keyword == "")
                    , Button.onClick AddBlockList
                    , Button.attrs [ class "btn-raised" ]
                    ]
                    [ text "Add" ]
                ]
            |> InputGroup.view
        , div
            [ style
                [ ( "max-height", "300px" )
                , ( "overflow-y", "scroll" )
                ]
            ]
            [ ListGroup.ul
                (urlList
                    |> List.map
                        (\x ->
                            ListGroup.li []
                                [ div
                                    [ style [ ( "display", "flex" ), ( "justify-content", "space-between" ) ]
                                    ]
                                    [ div [] [ text x ]
                                    , div [ style [ ( "cursor", "pointer" ), ( "width", "20px" ) ], DeleteBlockKeyword x |> onClick ] [ SolidIcon.trash_alt ]
                                    ]
                                ]
                        )
                )
            ]
        ]


searchResultList : String -> String -> List String -> List String -> List Item -> String -> List IndexInfo -> Html Msg
searchResultList logoUrl query tags deleteItems items tag indexInfo =
    div
        [ style
            [ ( "width", "100%" )
            ]
        ]
        [ div
            [ style
                [ ( "display", "flex" )
                , ( "align-items", "center" )
                , ( "min-height", "70px" )
                ]
            ]
            [ img
                [ src logoUrl
                , style
                    [ ( "width", "50px" )
                    , ( "height", "50px" )
                    ]
                ]
                []
            , InputGroup.config
                (InputGroup.text
                    [ query |> Input.value
                    , Input.placeholder "Enter search query"
                    , Input.onInput EditSearchQuery
                    , Input.attrs [ style [ ( "margin-right", "15px" ) ] ]
                    ]
                )
                |> InputGroup.predecessors
                    [ InputGroup.span
                        [ style [ ( "background-color", "#FEFEFE" ) ]
                        ]
                        [ div [ style [ ( "width", "15px" ) ] ] [ SolidIcon.search ] ]
                    ]
                |> InputGroup.view
            ]
        , div
            [ style
                [ ( "max-height", "100%" )
                , ( "border", "1px solid rgba(150,150,150,0.3)" )
                , ( "overflow-y", "scroll" )
                , ( "position", "absolute" )
                , ( "z-index", "9" )
                , ( "width", "99vw" )
                , ( "background-color", "#FEFEFE" )
                , if List.isEmpty items then
                    ( "display", "none" )
                  else
                    ( "display", "block" )
                ]
            ]
            (List.take 30 items
                |> uniqueBy (\x -> x.title)
                |> filter (\x -> not (member x.url deleteItems))
                |> List.map
                    (\x ->
                        searchItem tags indexInfo x query tag
                    )
            )
        ]


searchItem : List String -> List IndexInfo -> Item -> String -> String -> Html Msg
searchItem tags indexInfo item query tag =
    div [ style [ ( "margin", "12px" ), ( "padding", "5px" ) ] ]
        [ div []
            [ a
                [ href item.url
                , target "_blank"
                , style
                    [ ( "max-width", "90vw" )
                    , ( "white-space", "nowrap" )
                    , ( "text-overflow", "ellipsis" )
                    , ( "overflow", "hidden" )
                    , ( "display", "block" )
                    , ( "font-size", "0.95rem" )
                    , ( "color", "#2F0676" )
                    , ( "margin-bottom", "5px" )
                    , ( "text-decoration", "unset" )
                    , ( "text-align", "left" )
                    ]
                ]
                [ text item.title ]
            ]
        , div
            [ style
                [ ( "white-space", "wrap" )
                , ( "font-size", "0.7rem" )
                , ( "overflow", "hidden" )
                , ( "display", "block" )
                , ( "color", "#494949" )
                , ( "margin-bottom", "5px" )
                , ( "text-align", "left" )
                ]
            ]
            (List.concat
                (let
                    snipets =
                        split query item.snippet
                 in
                    if List.length snipets > 2 then
                        List.map
                            (\x ->
                                [ text x, strong [] [ text query ] ]
                            )
                            snipets
                    else
                        [ [ text item.snippet ] ]
                )
            )
        , div
            [ style
                [ ( "white-space", "nowrap" )
                , ( "font-size", "0.8rem" )
                , ( "text-overflow", "ellipsis" )
                , ( "overflow", "hidden" )
                , ( "display", "flex" )
                , ( "color", "#888" )
                , ( "width", "90vw" )
                , ( "text-align", "left" )
                ]
            ]
            [ span
                [ style
                    [ ( "width", "0.9rem" )
                    , ( "margin-top", "1px" )
                    , ( "margin-right", "3px" )
                    , case item.itemType of
                        "history" ->
                            ( "color", "#57AD3C" )

                        "bookmark" ->
                            ( "color", "#F5C50F" )

                        _ ->
                            ( "color", "#FF0045" )
                    ]
                ]
                [ if item.url == "" then
                    span [] []
                  else
                    (case item.itemType of
                        "history" ->
                            SolidIcon.history

                        "bookmark" ->
                            RegularIcon.bookmark

                        "pocket" ->
                            BrandsIcon.get_pocket

                        _ ->
                            SolidIcon.exclamation_circle
                    )
                ]
            , span
                [ style
                    [ ( "max-width", "100%" )
                    , ( "text-overflow", "ellipsis" )
                    , ( "white-space", "nowrap" )
                    , ( "overflow", "hidden" )
                    , ( "font-size", "0.8rem" )
                    ]
                ]
                [ text item.url ]
            ]
        , div []
            (List.map
                (\tag ->
                    Badge.badgeInfo
                        [ Spacing.ml1
                        , style [ ( "cursor", "pointer" ) ]
                        , onClick (SearchTag tag)
                        ]
                        [ text tag ]
                )
                (case find (\i -> i.url == item.url) indexInfo of
                    Just xs ->
                        xs.tags

                    Nothing ->
                        item.tags
                )
            )
        , Button.button
            [ Button.attrs
                [ style
                    [ ( "margin", "5px" )
                    , ( "width", "40px" )
                    , ( "height", "35px" )
                    ]
                ]
            , Button.onClick (Bookmark { url = item.url, bookmark = not item.bookmark, tags = item.tags, isInputting = False })
            , if item.bookmark then
                Button.info
              else
                Button.outlineInfo
            ]
            [ SolidIcon.star ]
        , Button.button
            [ Button.attrs
                [ style
                    [ ( "margin", "5px" )
                    , ( "width", "40px" )
                    , ( "height", "35px" )
                    ]
                ]
            , Button.onClick (InputTag { url = item.url, bookmark = item.bookmark, tags = item.tags, isInputting = False })
            , Button.success
            ]
            [ SolidIcon.tags ]
        , Button.button
            [ Button.attrs
                [ style
                    [ ( "margin", "5px" )
                    , ( "width", "40px" )
                    , ( "height", "35px" )
                    ]
                ]
            , Button.onClick (DeleteItem item.url)
            , Button.danger
            ]
            [ SolidIcon.trash_alt ]
        , case find (\i -> i.url == item.url) indexInfo of
            Just xs ->
                if xs.isInputting then
                    div [ style [ ( "width", "300px" ) ] ]
                        [ Input.text
                            [ Input.attrs
                                [ style
                                    [ ( "border-radius", "0" )
                                    , ( "margin-top", "10px" )
                                    , ( "margin-left", "5px" )
                                    , ( "width", "20vw" )
                                    ]
                                , placeholder "Add Tag"
                                , onEnter (AddTag { url = item.url, bookmark = not item.bookmark, tags = item.tags, isInputting = False })
                                ]
                            , Input.id item.url
                            , Input.value tag
                            , Input.onInput EditTag
                            ]
                        , tagList item.url
                            tags
                            xs.tags
                        ]
                else
                    span [] []

            Nothing ->
                span [] []
        ]


tagList : String -> List String -> List String -> Html Msg
tagList url tags selectedTags =
    div
        [ style
            [ ( "max-height", "300px" )
            , ( "overflow-y", "auto" )
            , ( "overflow-x", "hidden" )
            , ( "width", "100%" )
            ]
        ]
        [ ListGroup.ul
            (tags
                |> List.map
                    (\tag ->
                        ListGroup.li
                            [ ListGroup.attrs
                                [ style [ ( "margin-left", "5px" ), ( "width", "20vw" ) ]
                                ]
                            ]
                            [ label
                                [ style
                                    [ ( "cursor", "pointer" )
                                    , ( "display", "flex" )
                                    , ( "justify-content", "space-between" )
                                    ]
                                ]
                                [ div [] [ text tag ]
                                , Checkbox.checkbox
                                    [ Checkbox.id tag
                                    , Checkbox.inline
                                    , Checkbox.checked (member tag selectedTags)
                                    , Checkbox.attrs [ onClick (ChangeTag (member tag selectedTags) url tag) ]
                                    ]
                                    ""
                                ]
                            ]
                    )
            )
        ]
