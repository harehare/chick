module PopupView exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Lazy exposing (..)
import PopupModel exposing (..)
import FontAwesome.Solid as SolidIcon
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Form.Input as Input
import Bootstrap.Button as Button
import Html.Events.Extra exposing (onEnter)


view : Model -> Html Msg
view model =
    div
        [ style
            [ ( "width", "300px" )
            , ( "height", "40px" )
            , ( "font-family", "Montserrat" )
            , ( "font-size", "0.9rem" )
            , ( "background-color", "#FEFEFE" )
            ]
        ]
        [ lazy searchBox model.query
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
