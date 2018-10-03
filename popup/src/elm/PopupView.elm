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


view : Model -> Html Msg
view model =
    div
        [ style
            [ ( "width", "300px" )
            , ( "height", "40px" )
            , ( "font-family", "'Open Sans', sans-serif" )
            , ( "font-size", "0.9rem" )
            , ( "background-color", "#FEFEFE" )
            ]
        ]
        [ lazy searchBox model.query
        , lazy tagList model.tags
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
