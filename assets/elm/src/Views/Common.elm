module Views.Common exposing (..)

import Html exposing (Html, text, div, img)
import Html.Attributes exposing (class, src, style)
import Models.Application exposing (Msg)


waitForItems : List any -> (List any -> List (Html Msg) -> Html Msg) -> Html Msg
waitForItems items function =
    case items of
        [] ->
            div [ class "row" ]
                [ div [ class "col-md-12 text-center" ]
                    [ img [ src "/images/spinner.gif", style [ ( "width", "200px" ) ] ] []
                    ]
                ]

        x ->
            function x []
