module View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import List exposing (..)
import String exposing (split, words)
import Model exposing (..)
import FontAwesome.Solid as SolidIcon
import FontAwesome.Regular as RegularIcon
import FontAwesome.Brands as BrandsIcon


view : Model -> Html Msg
view model =
    if not model.visible || List.isEmpty model.items then
        span [] []
    else
        div
            [ style
                [ ( "position", "fixed" )
                , ( "top", toString model.top ++ "px" )
                , ( "right", toString model.right ++ "px" )
                , ( "z-index", "100" )
                , ( "background-color", "#FEFEFE" )
                , ( "font-family", "'Raleway', -apple-system, BlinkMacSystemFont, 'Hiragino Kaku Gothic ProN', Meiryo, sans-serif" )
                , ( "margin", "10px" )
                , ( "margin-top", "5px" )
                , ( "box-shadow", "0 2px 3px rgba(0,0,0,0.06)" )
                , ( "border", "1px solid rgba(150,150,150,0.3)" )
                , ( "max-width", "28vw" )
                ]
            ]
            [ div
                [ style
                    [ ( "cursor", "pointer" )
                    , ( "position", "absolute" )
                    , ( "top", "1px" )
                    , ( "right", "5px" )
                    , ( "margin-top", "5px" )
                    , ( "color", "rgba(0,0,0,.54)" )
                    , ( "width", "1.1rem" )
                    ]
                , onClick CloseSearchResult
                ]
                [ SolidIcon.times ]
            , div [ id "chick-list", style [ ( "overflow-y", "scroll" ), ( "max-height", "80vh" ) ] ]
                (List.take 20 model.items
                    |> List.map
                        (\x ->
                            div [ style [ ( "margin", "12px" ), ( "padding", "5px" ) ] ]
                                [ div []
                                    [ a
                                        [ href x.url
                                        , target "_blank"
                                        , style
                                            [ ( "max-width", "24vw" )
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
                                        [ text x.title ]
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
