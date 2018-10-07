module PopupView exposing (searchBox, tagList, view)

import Bootstrap.Badge as Badge
import Bootstrap.Button as Button
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Utilities.Spacing as Spacing
import FontAwesome.Solid as SolidIcon
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onEnter)
import Html.Lazy exposing (..)
import PopupModel exposing (..)
import List.Extra exposing (uniqueBy)
import Model exposing (Item)
import FontAwesome.Solid as SolidIcon
import FontAwesome.Regular as RegularIcon
import FontAwesome.Brands as BrandsIcon
import String exposing (split)


view : Model -> Html Msg
view model =
    div
        [ style
            [ ( "width", "500px" )
            , ( "font-family", "'Open Sans', sans-serif" )
            , ( "font-size", "0.9rem" )
            , ( "background-color", "#FEFEFE" )
            ]
        ]
        [ lazy searchBox model.query
        , lazy tagList model.tags
        , div [ style [ ( "overflow-y", "scroll" ), ( "max-height", "80vh" ) ] ]
            (model.items
                |> uniqueBy (\x -> x.title)
                |> List.map
                    (\x ->
                        searchItem x model.query
                    )
            )
        ]


searchBox : String -> Html Msg
searchBox query =
    div
        [ style
            [ ( "width", "95%" )
            , ( "margin", "0.5rem" )
            ]
        ]
        [ div
            [ style
                [ ( "display", "flex" )
                , ( "align-items", "center" )
                ]
            ]
            [ InputGroup.config
                (InputGroup.text
                    [ query |> Input.value
                    , Input.placeholder "Enter search query"
                    , Input.onInput EditSearchQuery
                    , Input.id "search-query"
                    , Input.attrs [ onEnter DoSearch ]
                    ]
                )
                |> InputGroup.successors
                    [ InputGroup.button
                        [ Button.onClick DoSearch
                        , Button.attrs [ style [ ( "border", "none" ) ] ]
                        ]
                        [ div [ style [ ( "width", "15px" ) ] ] [ SolidIcon.search ] ]
                    ]
                |> InputGroup.view
            ]
        ]


tagList : List String -> Html Msg
tagList tags =
    div []
        (tags
            |> List.map
                (\tag ->
                    Badge.badgeInfo
                        [ Spacing.ml1
                        , style
                            [ ( "cursor", "pointer" )
                            , ( "margin", "5px" )
                            , ( "padding", "5px" )
                            ]
                        , onClick (TagClick tag)
                        ]
                        [ text tag ]
                )
        )


searchItem : Item -> String -> Html Msg
searchItem item query =
    div [ style [ ( "margin", "12px" ), ( "padding", "5px" ) ] ]
        [ div []
            [ a
                [ href item.url
                , target "_blank"
                , style
                    [ ( "white-space", "nowrap" )
                    , ( "text-overflow", "ellipsis" )
                    , ( "overflow", "hidden" )
                    , ( "display", "block" )
                    , ( "font-size", "1.1rem" )
                    , ( "color", "#2F0676" )
                    , ( "margin-bottom", "5px" )
                    , ( "text-decoration", "none" )
                    , ( "text-align", "left" )
                    ]
                ]
                [ text item.title
                ]
            ]
        , div
            [ style
                [ ( "white-space", "wrap" )
                , ( "font-size", "0.8rem" )
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
                , ( "font-size", "0.85rem" )
                , ( "text-overflow", "ellipsis" )
                , ( "overflow", "hidden" )
                , ( "display", "flex" )
                , ( "color", "#888" )
                , ( "width", "33vw" )
                , ( "text-align", "left" )
                ]
            ]
            [ span
                [ style
                    [ ( "width", "0.85rem" )
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
                    [ ( "max-width", "80%" )
                    , ( "text-overflow", "ellipsis" )
                    , ( "white-space", "nowrap" )
                    , ( "overflow", "hidden" )
                    ]
                ]
                [ text item.url ]
            ]
        , div []
            (List.map
                (\tag ->
                    Badge.badgeInfo
                        [ Spacing.ml1
                        , style
                            [ ( "cursor", "pointer" )
                            , ( "color", "#fff" )
                            , ( "background-color", "#17a2b8" )
                            , ( "display", "inline-block" )
                            , ( "padding", ".25em .4em" )
                            , ( "font-size", "75%" )
                            , ( "font-weight", "700" )
                            , ( "line-height", "1" )
                            , ( "text-align", "center" )
                            , ( "white-space", "nowrap" )
                            , ( "vertical-align", "baseline" )
                            , ( "border-radius", ".25rem" )
                            , ( "margin-left", ".25rem" )
                            ]
                        ]
                        [ text tag ]
                )
                item.tags
            )
        ]
