module Views.Document exposing (..)

import Html exposing (Html, div, h1, text, input, img)
import Html.Attributes exposing (class, classList, src, style)
import Models exposing (AppState, Msg)


index : AppState -> String -> Html Msg
index model document_id =
    div []
        [ div [ class "col-md-10" ]
            [ img [ src ("/documents/" ++ document_id), style [ ( "max-width", "100%" ) ] ] []
            ]
        , div [ class "col-md-2" ] []
        ]
