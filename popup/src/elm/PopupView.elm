module PopupView exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (..)
import PopupModel exposing (..)
import Bootstrap.Progress as Progress
import FontAwesome.Solid as SolidIcon


view : Model -> Html Msg
view model =
    div
        [ style
            [ ( "width", "280px" )
            , ( "height"
              , if model.status.documentCount - model.status.indexedCount > 0 then
                    "35px"
                else
                    "30px"
              )
            , ( "font-family", "Montserrat" )
            , ( "font-size", "0.9rem" )
            , ( "margin", "10px" )
            , ( "display", "flex" )
            , ( "justify-content", "space-between" )
            , ( "align-items", "center" )
            ]
        ]
        [ lazy indexingStatus model.status
        , lazy2 optionButton model.suspend model.status
        ]


optionButton : Bool -> IndexStatus -> Html Msg
optionButton suspend status =
    div
        [ style
            [ ( "display", "flex" )
            , ( "flex-direction", "column" )
            , ( "justify-content", "space-between" )
            ]
        ]
        [ div
            [ style
                [ ( "width", "20px" )
                , ( "cursor", "pointer" )
                ]
            , onClick ShowOption
            ]
            [ SolidIcon.cog ]
        , if status.documentCount > status.indexedCount then
            div
                [ style
                    [ ( "width", "20px" )
                    , ( "cursor", "pointer" )
                    , ( "margin-left", "2px" )
                    ]
                , onClick SuspendResume
                ]
                [ if suspend then
                    SolidIcon.play
                  else
                    SolidIcon.pause
                ]
          else
            span [] []
        ]


indexingStatus : IndexStatus -> Html Msg
indexingStatus status =
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
                [ ( "display", "flex" )
                , ( "flex-direction", "column" )
                , ( "justify-content", "space-around" )
                ]
            ]
            [ if status.documentCount == 0 && status.indexedCount == 0 then
                div [ style [ ( "font-size", "0.85rem" ), ( "width", "220px" ) ] ] [ text "Loading..." ]
              else
                div [ style [ ( "font-size", "0.85rem" ), ( "width", "220px" ) ] ] [ text ((toString status.indexedCount) ++ " items indexed complete") ]
            , if status.documentCount == 0 && status.indexedCount == 0 then
                Progress.progress [ Progress.info, Progress.animated, Progress.value 100 ]
              else if status.documentCount - status.indexedCount > 0 then
                Progress.progress [ Progress.info, Progress.value currentStatus ]
              else
                span [] []
            ]
