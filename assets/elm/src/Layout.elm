module Layout exposing (..)

import Html exposing (Html, div, text, h3, nav, ul, li, a)
import Html.Attributes exposing (class, classList, href)


layout : Html msg -> Html msg
layout body =
    div [ class "container" ]
        [ div [ class "masthead" ]
            [ h3 [ class "text-muted" ] [ text "DMS 42" ]
            , nav []
                [ ul [ classList [ ( "nav", True ), ( "nav-justified", True ) ] ]
                    [ li [ classList [ ( "active", True ) ] ]
                        [ a [ href "#" ] [ text "Search" ]
                        ]
                    , li [ classList [ ( "active", False ) ] ]
                        [ a [ href "#" ] [ text "Documents" ]
                        ]
                    , li [ classList [ ( "active", False ) ] ]
                        [ a [ href "#" ] [ text "Settings" ]
                        ]
                    ]
                ]
            ]
        , body
        ]
