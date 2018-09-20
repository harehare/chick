module OptionView exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (..)
import List exposing (filter, member)
import List.Extra exposing (uniqueBy)
import String exposing (split)
import OptionModel exposing (..)
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Form.Input as Input
import Bootstrap.Button as Button
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.ListGroup as ListGroup
import FontAwesome.Solid as SolidIcon
import FontAwesome.Brands as BrandsIcon
import FontAwesome.Regular as RegularIcon
import Bootstrap.Form as Form
import Bootstrap.Progress as Progress
import Model exposing (Item)
import Bootstrap.Alert as Alert


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
                , ( "box-shadow", "0 2px 3px rgba(0,0,0,0.06)" )
                , ( "display", "flex" )
                , ( "align-items", "center" )
                ]
            ]
            [ lazy3 (searchResultList model.logoUrl) model.query model.deleteUrlList model.searchResult
            ]
        , lazy2 dataImport model.status model.indexTarget
        , lazy viewOption model.viewOption
        , lazy2 blackUrlList model.blockKeyword model.blockList
        , lazy buttonArea model.changed
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


advanced : ApiStatus -> Html Msg
advanced status =
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
                [ ( "margin-bottom", "15px" )
                , ( "font-weight", "300" )
                ]
            ]
            [ text "ADVANCED" ]
        , div [ style [ ( "margin-bottom", "5px" ) ] ]
            [ Form.label
                [ style
                    [ ( "font-weight", "300" )
                    , ( "font-size", "0.8rem" )
                    ]
                , for "index-api"
                ]
                [ text "Index Extended API" ]
            , InputGroup.config (InputGroup.text [ status.url |> Input.value, Input.id "index-api", Input.placeholder "Enter URL", Input.onInput EditApiUrl ])
                |> InputGroup.successors
                    [ InputGroup.button
                        [ Button.disabled (status.url == "")
                        , if status.verify then
                            Button.success
                          else
                            Button.danger
                        , Button.onClick VerifySearchApi
                        ]
                        [ text "Verify" ]
                    ]
                |> InputGroup.view
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


searchResultList : String -> String -> List String -> List Item -> Html Msg
searchResultList logoUrl query deleteItems items =
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
                , ( "z-index", "1" )
                , ( "background-color", "#FEFEFE" )
                , if List.isEmpty items then
                    ( "display", "none" )
                  else
                    ( "display", "block" )
                ]
            ]
            (List.take 20 items
                |> uniqueBy (\x -> x.title)
                |> filter (\x -> not (member x.url deleteItems))
                |> List.map
                    (\x ->
                        div [ style [ ( "margin", "12px" ), ( "padding", "5px" ) ] ]
                            [ div []
                                [ a
                                    [ href x.url
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
                                    [ text x.title ]
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
                                            split query x.snippet
                                     in
                                        if List.length snipets > 2 then
                                            List.map
                                                (\x ->
                                                    [ text x, strong [] [ text query ] ]
                                                )
                                                snipets
                                        else
                                            [ [ text x.snippet ] ]
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
                                        , case x.itemType of
                                            "history" ->
                                                ( "color", "#57AD3C" )

                                            "bookmark" ->
                                                ( "color", "#F5C50F" )

                                            _ ->
                                                ( "color", "#FF0045" )
                                        ]
                                    ]
                                    [ if x.url == "" then
                                        span [] []
                                      else
                                        (case x.itemType of
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
                                    [ text x.url ]
                                ]
                            , Button.button
                                [ Button.attrs
                                    [ style
                                        [ ( "margin", "5px" )
                                        , ( "width", "40px" )
                                        , ( "height", "35px" )
                                        ]
                                    ]
                                , Button.onClick (Bookmark { url = x.url, bookmark = not x.bookmark })
                                , if x.bookmark then
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
                                , Button.onClick (DeleteItem x.url)
                                , Button.danger
                                ]
                                [ SolidIcon.trash_alt ]
                            ]
                    )
            )
        ]


buttonArea : Bool -> Html Msg
buttonArea changed =
    div
        [ style
            [ ( "justify-content", "flex-end" )
            , ( "display", "flex" )
            , ( "flex-grow", "2" )
            ]
        ]
        [ Button.button
            [ Button.disabled (not changed)
            , Button.info
            , Button.attrs [ style [ ( "margin", "15px" ) ] ]
            , Button.onClick Save
            ]
            [ text "Save" ]
        ]
