module Views.Settings exposing (..)

import Html exposing (Html, div, h1, text, input, img, a, span)
import Html.Attributes exposing (class, classList, src, href, title, style)
import Models.Application exposing (..)
import Formatting exposing (s, float, (<>), print)


index : Models.Application.AppModel -> Html msg
index model =
    div [ class "row" ]
        [ div [ class "col-md-2" ]
            [ tile "Tags" "#settings/tags" 2.3
            ]
        , div [ class "col-md-2" ]
            [ tile "Document types" "#settings/document-types" 1.6
            ]
        ]


tile : String -> String -> Float -> Html msg
tile name path size =
    div [ style [ ( "vertical-align", "middle" ), ( "font-size", print (Formatting.float <> s "em") size ) ], class "img-rounded text-center tile" ]
        [ a [ href path ] [ div [] [ text name ] ]
        ]
