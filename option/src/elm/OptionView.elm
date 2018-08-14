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
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import FontAwesome.Solid as SolidIcon
import FontAwesome.Brands as BrandsIcon
import FontAwesome.Regular as RegularIcon
import Bootstrap.Form as Form
import Bootstrap.Progress as Progress
import PopupModel exposing (IndexStatus)
import Model exposing (Item)


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
            , ( "font-family", "'Montserrat', sans-serif" )
            ]
        ]
        [ div
            [ style
                [ ( "background-color", "#2593E5" )
                , ( "height", "50px" )
                , ( "display", "flex" )
                , ( "align-items", "center" )
                ]
            ]
            [ h5
                [ style
                    [ ( "color", "#FFF" )
                    , ( "margin-left", "10px" )
                    , ( "font-family", "'Montserrat', sans-serif" )
                    , ( "margin-top", "5px" )
                    ]
                ]
                [ text "Chick Options" ]
            ]
        , lazy3 searchResultList model.query model.deleteUrlList model.searchResult
        , lazy indexStatus model.status
        , lazy viewOption model.viewOption
        , lazy indexOption model.indexTarget
        , lazy2 blackUrlList model.blockKeyword model.blockList
        , lazy positionOption model.position
        , lazy indexOperation model.isIndexing
        , lazy advancedOptions model.advancedOption
        , lazy buttonArea model.changed
        ]


positionOption : Position -> Html Msg
positionOption pos =
    div
        [ style
            [ ( "box-shadow", "0 2px 3px rgba(0,0,0,0.06)" )
            , ( "border", "1px solid rgba(150,150,150,0.3)" )
            , ( "padding", "1% 2%" )
            , ( "margin", "15px" )
            , ( "background-color", "#FEFEFE" )
            ]
        ]
        [ h5 [ style [ ( "font-family", "'Montserrat', sans-serif" ) ] ] [ text "Display position" ]
        , Grid.row []
            [ Grid.col [ Col.lg6 ]
                [ InputGroup.config (InputGroup.text [ Input.attrs [ id "top-input", onFocus (SelectText "top-input") ], toString pos.top |> Input.value, Input.placeholder "Top", Input.onInput (EditPosition "top") ])
                    |> InputGroup.predecessors
                        [ InputGroup.span [] [ text "Top" ] ]
                    |> InputGroup.view
                ]
            , Grid.col [ Col.lg6 ]
                [ InputGroup.config (InputGroup.text [ Input.attrs [ id "right-input", onFocus (SelectText "right-input") ], toString pos.right |> Input.value, Input.placeholder "Right", Input.onInput (EditPosition "right") ])
                    |> InputGroup.predecessors
                        [ InputGroup.span [] [ text "Right" ] ]
                    |> InputGroup.view
                ]
            ]
        ]


viewOption : ViewOption -> Html Msg
viewOption option =
    div
        [ style
            [ ( "box-shadow", "0 2px 3px rgba(0,0,0,0.06)" )
            , ( "border", "1px solid rgba(150,150,150,0.3)" )
            , ( "padding", "1% 2%" )
            , ( "margin", "15px" )
            , ( "background-color", "#FEFEFE" )
            ]
        ]
        [ h5 [ style [ ( "font-family", "'Montserrat', sans-serif" ) ] ] [ text "Show chick results" ]
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


indexStatus : IndexStatus -> Html Msg
indexStatus status =
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
    in
        div
            [ style
                [ ( "box-shadow", "0 2px 3px rgba(0,0,0,0.06)" )
                , ( "border", "1px solid rgba(150,150,150,0.3)" )
                , ( "padding", "1% 2%" )
                , ( "margin", "15px" )
                , ( "background-color", "#FEFEFE" )
                ]
            ]
            [ h5 [ style [ ( "font-family", "'Montserrat', sans-serif" ) ] ]
                [ text "Index Status" ]
            , div
                [ style [ ( "font-size", "0.9rem" ), ( "width", "230px" ) ] ]
                [ text ((toString status.indexedCount) ++ " items indexed complete") ]
            , if status.documentCount - status.indexedCount > 0 then
                Progress.progress [ Progress.info, Progress.value currentStatus ]
              else
                span [] []
            ]


indexOption : IndexTarget -> Html Msg
indexOption option =
    div
        [ style
            [ ( "box-shadow", "0 2px 3px rgba(0,0,0,0.06)" )
            , ( "border", "1px solid rgba(150,150,150,0.3)" )
            , ( "padding", "1% 2%" )
            , ( "margin", "15px" )
            , ( "background-color", "#FEFEFE" )
            ]
        ]
        [ h5 [ style [ ( "font-family", "'Montserrat', sans-serif" ) ] ] [ text "Index for search" ]
        , Checkbox.checkbox
            [ Checkbox.id "bookmark", Checkbox.inline, Checkbox.checked option.bookmark, Checkbox.attrs [ ChangeIndexTarget "bookmark" |> onClick ] ]
            "Bookmark"
        , Checkbox.checkbox
            [ Checkbox.id "history", Checkbox.inline, Checkbox.checked option.history, Checkbox.attrs [ ChangeIndexTarget "history" |> onClick ] ]
            "History"
        ]


blackUrlList : String -> List String -> Html Msg
blackUrlList keyword urlList =
    div
        [ style
            [ ( "box-shadow", "0 2px 3px rgba(0,0,0,0.06)" )
            , ( "border", "1px solid rgba(150,150,150,0.3)" )
            , ( "padding", "1% 2%" )
            , ( "margin", "15px" )
            , ( "background-color", "#FEFEFE" )
            ]
        ]
        [ h5 [ style [ ( "font-family", "'Montserrat', sans-serif" ) ] ] [ text "Blocking and filtering" ]
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


indexOperation : Bool -> Html Msg
indexOperation isIndexing =
    div
        [ style
            [ ( "box-shadow", "0 2px 3px rgba(0,0,0,0.06)" )
            , ( "border", "1px solid rgba(150,150,150,0.3)" )
            , ( "padding", "1% 2%" )
            , ( "margin", "15px" )
            , ( "background-color", "#FEFEFE" )
            ]
        ]
        [ h5 [ style [ ( "font-family", "'Montserrat', sans-serif" ) ] ] [ text "Indexing operation" ]
        , Button.button
            [ Button.attrs [ style [ ( "margin", "15px" ), ( "width", "165px" ), ( "height", "45px" ) ] ]
            , Button.onClick Export
            , Button.outlineDark
            ]
            [ div
                [ style
                    [ ( "display", "flex" )
                    , ( "align-items", "center" )
                    , ( "justify-content", "space-between" )
                    ]
                ]
                [ div
                    [ style
                        [ ( "width", "30px" )
                        , ( "color", "#000" )
                        ]
                    ]
                    [ SolidIcon.download ]
                , div [ style [ ( "margin-bottom", "7px" ) ] ] [ text "Export index" ]
                ]
            ]
        , Button.button
            [ Button.attrs [ style [ ( "margin", "15px" ), ( "width", "165px" ), ( "height", "45px" ) ] ]
            , Button.onClick ImportPocket
            , Button.outlineDark
            ]
            [ div
                [ style
                    [ ( "display", "flex" )
                    , ( "align-items", "center" )
                    , ( "justify-content", "space-between" )
                    ]
                ]
                [ div
                    [ style
                        [ ( "width", "30px" )
                        , ( "color", "#FF0045" )
                        ]
                    ]
                    [ BrandsIcon.get_pocket ]
                , div [ style [ ( "margin-bottom", "7px" ) ] ] [ text "Import pocket" ]
                ]
            ]
        , Button.button
            [ Button.attrs [ style [ ( "width", "160px" ), ( "margin", "15px" ), ( "height", "45px" ) ] ]
            , Button.onClick Reindexing
            , Button.outlineDark
            ]
            [ div
                [ style
                    [ ( "display", "flex" )
                    , ( "align-items", "center" )
                    , ( "justify-content", "space-between" )
                    ]
                ]
                [ div
                    [ style
                        [ ( "width", "30px" )
                        , ( "color", "#417AF7" )
                        ]
                    ]
                    [ SolidIcon.sync ]
                , div [ style [ ( "margin-bottom", "7px" ) ] ] [ text "Re-Indexing" ]
                ]
            ]
        , Button.button
            [ Button.attrs [ style [ ( "margin", "15px" ), ( "width", "175px" ), ( "height", "45px" ) ] ]
            , Button.onClick DeleteIndex
            , Button.outlineDark
            ]
            [ div
                [ style
                    [ ( "display", "flex" )
                    , ( "align-items", "center" )
                    , ( "justify-content", "space-between" )
                    ]
                ]
                [ div
                    [ style
                        [ ( "width", "30px" )
                        , ( "color", "#008709" )
                        ]
                    ]
                    [ SolidIcon.trash ]
                , div [ style [ ( "margin-bottom", "7px" ) ] ] [ text "Delete index all" ]
                ]
            ]
        ]


advancedOptions : Advanced -> Html Msg
advancedOptions ad =
    div
        [ style
            [ ( "box-shadow", "0 2px 3px rgba(0,0,0,0.06)" )
            , ( "border", "1px solid rgba(150,150,150,0.3)" )
            , ( "padding", "1% 2%" )
            , ( "margin", "15px" )
            , ( "background-color", "#FEFEFE" )
            ]
        ]
        [ h5
            [ style
                [ ( "margin-bottom", "15px" )
                , ( "font-family", "'Montserrat', sans-serif" )
                ]
            ]
            [ text "Advanced option" ]
        , div [ style [ ( "margin-bottom", "5px" ) ] ]
            [ Form.label
                [ style
                    [ ( "font-family", "'Montserrat', sans-serif" )
                    , ( "font-size", "0.8rem" )
                    ]
                , for "scraping-api"
                ]
                [ text "Scraping API" ]
            , InputGroup.config (InputGroup.text [ ad.scrapingApi.url |> Input.value, Input.placeholder "Scraping API", Input.id "scraping-api", Input.onInput (EditApiUrl Scraping) ])
                |> InputGroup.successors
                    [ InputGroup.button
                        [ Button.disabled (ad.scrapingApi.url == "")
                        , if ad.scrapingApi.verify then
                            Button.success
                          else
                            Button.danger
                        , Button.onClick VerifyScrapingApi
                        ]
                        [ text "Verify" ]
                    ]
                |> InputGroup.view
            ]
        , div [ style [ ( "margin-bottom", "10px" ) ] ]
            [ Form.label
                [ style
                    [ ( "font-family", "'Montserrat', sans-serif" )
                    , ( "font-size", "0.8rem" )
                    ]
                , for "queryparse-api"
                ]
                [ text "Query Parse API" ]
            , InputGroup.config (InputGroup.text [ ad.queryParseApi.url |> Input.value, Input.placeholder "Query Parse API", Input.id "queryparse-api", Input.onInput (EditApiUrl QueryParse) ])
                |> InputGroup.successors
                    [ InputGroup.button
                        [ Button.disabled (ad.queryParseApi.url == "")
                        , if ad.queryParseApi.verify then
                            Button.success
                          else
                            Button.danger
                        , Button.onClick VerifyQueryParseApi
                        ]
                        [ text "Verify" ]
                    ]
                |> InputGroup.view
            ]
        , div [ style [ ( "margin-bottom", "10px" ) ] ]
            [ Form.label
                [ style
                    [ ( "font-family", "'Montserrat', sans-serif" )
                    , ( "font-size", "0.8rem" )
                    ]
                , for "scoring-api"
                ]
                [ text "Scoring API" ]
            , InputGroup.config (InputGroup.text [ ad.scoringApi.url |> Input.value, Input.placeholder "Scoring API", Input.id "scoring-api", Input.onInput (EditApiUrl Scoring) ])
                |> InputGroup.successors
                    [ InputGroup.button
                        [ Button.disabled (ad.scoringApi.url == "")
                        , if ad.scoringApi.verify then
                            Button.success
                          else
                            Button.danger
                        , Button.onClick VerifyScoringApi
                        ]
                        [ text "Verify" ]
                    ]
                |> InputGroup.view
            , a
                [ style
                    [ ( "margin-top", "10px" )
                    , ( "display", "inline-block" )
                    ]
                , href "https://chick-search.herokuapp.com/index.html"
                ]
                [ text "Api specification" ]
            ]
        ]


searchResultList : String -> List String -> List Item -> Html Msg
searchResultList query deleteItems items =
    div
        [ style
            [ ( "box-shadow", "0 2px 3px rgba(0,0,0,0.06)" )
            , ( "border", "1px solid rgba(150,150,150,0.3)" )
            , ( "padding", "1% 2%" )
            , ( "margin", "15px" )
            , ( "background-color", "#FEFEFE" )
            ]
        ]
        [ h5 [ style [ ( "font-family", "'Montserrat', sans-serif" ) ] ] [ text "Search" ]
        , InputGroup.config
            (InputGroup.text
                [ query |> Input.value
                , Input.placeholder "Enter search query"
                , Input.onInput EditSearchQuery
                ]
            )
            |> InputGroup.view
        , div
            [ style
                [ ( "max-height", "400px" )
                , ( "overflow-y", "scroll" )
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
                                        [ ( "max-width", "80%" )
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
            ]
        ]
        [ Button.button
            [ Button.disabled (not changed)
            , Button.secondary
            , Button.attrs [ style [ ( "margin", "15px" ) ] ]
            , Button.onClick Save
            ]
            [ text "Save" ]
        ]
