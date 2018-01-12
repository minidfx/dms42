module Views.Home exposing (..)

import Html exposing (Html, div, h1, text, input)
import Html.Attributes exposing (class, classList)
import Models.Application exposing (..)


index : Models.Application.AppModel -> Html msg
index model =
    div [ class "jumbotron" ]
        [ h1 [] [ text "Search" ]
        , div [ class "row" ]
            [ div [ classList [ ( "col-md-10", True ), ( "col-md-offset-1", True ) ] ]
                [ input [ class "form-control" ] []
                ]
            ]
        ]
