module View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import List exposing (..)
import List.Extra exposing (uniqueBy)
import String exposing (split, words)
import Model exposing (..)
import FontAwesome.Solid as SolidIcon
import FontAwesome.Regular as RegularIcon
import FontAwesome.Brands as BrandsIcon


view : Model -> Html Msg
view model =
    if List.isEmpty model.items then
        span [] []
    else
        div []
            [ div
                [ onClick ToggleSearchResult
                , style
                    [ ( "position", "fixed" )
                    , ( "top", "135px" )
                    , ( "right", "1px" )
                    , ( "z-index", "110" )
                    , ( "width", "50px" )
                    , ( "height", "50px" )
                    , ( "cursor", "pointer" )
                    , ( "background-color"
                      , if model.visible then
                            "#FEFEFE"
                        else
                            "#CCCCCC"
                      )
                    , ( "opacity"
                      , if model.visible then
                            "1.0"
                        else
                            "0.5"
                      )
                    , ( "box-shadow", "0 2px 3px rgba(0,0,0,0.06)" )
                    , ( "border-radius", "5px" )
                    , ( "border-top", "1px solid rgba(150,150,150,0.3)" )
                    , ( "border-bottom", "1px solid rgba(150,150,150,0.3)" )
                    , ( "border-left", "1px solid rgba(150,150,150,0.3)" )
                    ]
                ]
                [ img
                    [ src model.imageUrl
                    , style
                        [ ( "width", "50px" )
                        , ( "height", "50px" )
                        ]
                    ]
                    []
                ]
            , div
                [ style
                    [ ( "position", "fixed" )
                    , ( "top", "130px" )
                    , ( "right"
                      , if model.visible then
                            "-1px"
                        else
                            "-450px"
                      )
                    , ( "z-index", "100" )
                    , ( "background-color", "#FEFEFE" )
                    , ( "font-family", "'Montserrat', -apple-system, BlinkMacSystemFont, 'Hiragino Kaku Gothic ProN', Meiryo, sans-serif" )
                    , ( "margin-top", "5px" )
                    , ( "border-radius", "5px" )
                    , ( "box-shadow", "0 2px 3px rgba(0,0,0,0.06)" )
                    , ( "border-top", "1px solid rgba(150,150,150,0.3)" )
                    , ( "border-bottom", "1px solid rgba(150,150,150,0.3)" )
                    , ( "border-left", "1px solid rgba(150,150,150,0.3)" )
                    , ( "width", "450px" )
                    ]
                ]
                [ div [ id "chick-list", style [ ( "overflow-y", "scroll" ), ( "max-height", "80vh" ) ] ]
                    (List.take 25 model.items
                        |> uniqueBy (\x -> x.title)
                        |> List.map
                            (\x ->
                                div [ style [ ( "margin", "12px" ), ( "padding", "5px" ) ] ]
                                    [ div []
                                        [ a
                                            [ href x.url
                                            , target "_blank"
                                            , style
                                                [ ( "max-width", "23vw" )
                                                , ( "white-space", "nowrap" )
                                                , ( "text-overflow", "ellipsis" )
                                                , ( "overflow", "hidden" )
                                                , ( "display", "block" )
                                                , ( "font-size", "1.3rem" )
                                                , ( "color", "#2F0676" )
                                                , ( "margin-bottom", "5px" )
                                                , ( "text-decoration", "unset" )
                                                , ( "text-align", "left" )
                                                ]
                                            ]
                                            [ if x.bookmark then
                                                span
                                                    [ style
                                                        [ ( "display", "inline-block" )
                                                        , ( "width", "1.0rem" )
                                                        , ( "margin-right", "5px" )
                                                        , ( "color", "#5879DB" )
                                                        ]
                                                    ]
                                                    [ SolidIcon.star ]
                                              else
                                                span [] []
                                            , text x.title
                                            ]
                                        ]
                                    , div
                                        [ style
                                            [ ( "white-space", "wrap" )
                                            , ( "font-size", "0.85rem" )
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
                                                    split model.query x.snippet
                                             in
                                                if List.length snipets > 2 then
                                                    List.map
                                                        (\x ->
                                                            [ text x, strong [] [ text model.query ] ]
                                                        )
                                                        snipets
                                                else
                                                    [ [ text x.snippet ] ]
                                            )
                                        )
                                    , div
                                        [ style
                                            [ ( "white-space", "nowrap" )
                                            , ( "font-size", "0.9rem" )
                                            , ( "text-overflow", "ellipsis" )
                                            , ( "overflow", "hidden" )
                                            , ( "display", "flex" )
                                            , ( "color", "#888" )
                                            , ( "width", "25vw" )
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
                                                ]
                                            ]
                                            [ text x.url ]
                                        ]
                                    ]
                            )
                    )
                , div
                    [ style
                        [ ( "display", "flex" )
                        , ( "justify-content", "flex-end" )
                        ]
                    ]
                    [ span
                        [ style
                            [ ( "font-family", "'Anton', sans-serif" )
                            , ( "font-size", "9px" )
                            , ( "color", "#2593E5" )
                            , ( "font-weight", "600" )
                            , ( "margin", "5px" )
                            ]
                        ]
                        [ text "powered by CHICK" ]
                    ]
                ]
            ]
