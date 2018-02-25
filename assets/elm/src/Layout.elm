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
isDocumentsActive { route } =
    case route of
        Routing.Documents ->
            isActive Routing.Documents route

        Routing.AddDocuments ->
            isActive (Routing.AddDocuments) route

        Routing.Document x ->
            isActive (Routing.Document x) route

        Routing.DocumentProperties x ->
            isActive (Routing.DocumentProperties x) route

        _ ->
            False


layout : AppState -> Html Msg -> Html Msg
layout appState body =
    div [ class "container" ]
        [ div [ class "masthead" ]
            [ h3 [ class "text-muted app-title" ] [ a [ href "#" ] [ text "DMS ", span [ class "color-42" ] [ text "42" ] ] ]
            , nav [ class "navbar navbar-default" ]
                [ div [ class "navbar-header" ]
                    [ a [ class "navbar-brand" ] []
                    , ul
                        [ class "nav nav-justified" ]
                        [ menu "Search" "#home" (isActive Routing.Home appState.route)
                        , menu "Documents" "#documents" (isDocumentsActive appState)
                        , menu "Settings" "#settings" (isActive Routing.Settings appState.route)
                        ]
                    ]
                ]
            ]
        , body
        ]
