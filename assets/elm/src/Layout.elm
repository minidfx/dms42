module Layout exposing (..)

import Html exposing (Html, div, text, h3, nav, ul, li, a)
import Html.Attributes exposing (class, classList, href)
import Models.Application exposing (..)
import Routing exposing (..)


layout : Models.Application.AppModel -> Html msg -> Html msg
layout model body =
    div [ class "container" ]
        [ div [ class "masthead" ]
            [ h3 [ class "text-muted" ] [ text "DMS 42" ]
            , nav []
                [ ul [ classList [ ( "nav", True ), ( "nav-justified", True ) ] ]
                    [ li [ classList [ ( "active", (isActive Routing.Home model.route) ) ] ]
                        [ a [ href "#home" ] [ text "Search" ]
                        ]
                    , li [ classList [ ( "active", (isActive Routing.Documents model.route) || (isActive (Routing.Document 0) model.route) ) ] ]
                        [ a [ href "#documents" ] [ text "Documents" ]
                        ]
                    , li [ classList [ ( "active", (isActive Routing.Settings model.route) ) ] ]
                        [ a [ href "#settings" ] [ text "Settings" ]
                        ]
                    ]
                ]
            ]
        , body
        ]


isActive : Routing.Route -> Routing.Route -> Bool
isActive expectedRoute route =
    (==) expectedRoute route
