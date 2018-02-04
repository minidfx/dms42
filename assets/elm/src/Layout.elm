module Layout exposing (..)

import Html exposing (Html, div, text, h3, nav, ul, li, a, span)
import Html.Attributes exposing (class, classList, href)
import Models exposing (AppState, Msg)
import Routing exposing (..)
import String exposing (any)


menu : String -> String -> Bool -> Html Msg
menu name path isActive =
    li [ classList [ ( "active", isActive ) ] ]
        [ a [ href path ] [ text name ]
        ]


isActive : Routing.Route -> Routing.Route -> Bool
isActive expectedRoute route =
    (==) expectedRoute route


isDocumentsActive : AppState -> Bool
isDocumentsActive appState =
    (isActive Routing.Documents appState.route) || (isActive (Routing.Document "0") appState.route) || (isActive (Routing.AddDocuments) appState.route)


layout : AppState -> Html Msg -> Html Msg
layout appState body =
    div [ class "container" ]
        [ div [ class "masthead" ]
            [ h3 [ class "text-muted app-title" ] [ a [ href "#" ] [ text "DMS ", span [ class "color-42" ] [ text "42" ] ] ]
            , nav []
                [ ul [ classList [ ( "nav", True ), ( "nav-justified", True ) ] ]
                    [ menu "Search" "#home" (isActive Routing.Home appState.route)
                    , menu "Documents" "#documents" (isDocumentsActive appState)
                    , menu "Settings" "#settings" (isActive Routing.Settings appState.route)
                    ]
                ]
            ]
        , body
        ]
