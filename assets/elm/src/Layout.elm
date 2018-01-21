module Layout exposing (..)

import Html exposing (Html, div, text, h3, nav, ul, li, a, span)
import Html.Attributes exposing (class, classList, href)
import Models.Application exposing (..)
import Routing exposing (..)
import Models.Msgs exposing (..)


menu : String -> String -> Bool -> Html Msg
menu name path isActive =
    li [ classList [ ( "active", isActive ) ] ]
        [ a [ href path ] [ text name ]
        ]


isActive : Routing.Route -> Routing.Route -> Bool
isActive expectedRoute route =
    (==) expectedRoute route


isDocumentsActive : Models.Application.AppModel -> Bool
isDocumentsActive model =
    (isActive Routing.Documents model.route) || (isActive (Routing.Document 0) model.route) || (isActive (Routing.AddDocuments) model.route)


layout : Models.Application.AppModel -> Html Msg -> Html Msg
layout model body =
    div [ class "container" ]
        [ div [ class "masthead" ]
            [ h3 [ class "text-muted app-title" ] [ a [ href "#" ] [ text "DMS ", span [ class "color-42" ] [ text "42" ] ] ]
            , nav []
                [ ul [ classList [ ( "nav", True ), ( "nav-justified", True ) ] ]
                    [ menu "Search" "#home" (isActive Routing.Home model.route)
                    , menu "Documents" "#documents" (isDocumentsActive model)
                    , menu "Settings" "#settings" (isActive Routing.Settings model.route)
                    ]
                ]
            ]
        , body
        ]
