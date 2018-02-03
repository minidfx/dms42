module Views.Common exposing (..)

import Html exposing (Html, text, div, img, a)
import Html.Attributes exposing (class, src, style, attribute)
import Models exposing (Msg)


waitForItems : Maybe (List any) -> (List any -> List (Html Msg) -> Html Msg) -> Html Msg
waitForItems items function =
    case items of
        Nothing ->
            div [ class "row" ]
                [ div [ class "col-md-12 text-center" ]
                    [ img [ src "/images/spinner.gif", style [ ( "width", "200px" ) ] ] []
                    ]
                ]

        Just x ->
            case x of
                [] ->
                    div [ class "alert alert-info", attribute "role" "alert" ]
                        [ text "No items"
                        ]

                x ->
                    function x []
