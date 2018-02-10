module Views.Document exposing (..)

import Html exposing (Html, div, h1, text, input, img, button)
import Html.Attributes exposing (class, classList, src, attribute, style, type_)
import Models exposing (AppState, Msg)
import Routing exposing (Route(Document, DocumentProperties))


isActive : Routing.Route -> Routing.Route -> Bool
isActive expectedRoute route =
    (==) expectedRoute route


isPreviewActive : AppState -> Bool
isPreviewActive { route } =
    case route of
        Routing.Document x ->
            isActive (Routing.Document x) route

        _ ->
            False


isDocumentPropertiesActive : AppState -> Bool
isDocumentPropertiesActive { route } =
    case route of
        Routing.DocumentProperties x ->
            isActive (Routing.DocumentProperties x) route

        _ ->
            False


index : AppState -> String -> Html Msg
index appState document_id =
    div []
        [ div [ class "col-md-10" ]
            [ img [ src ("/documents/" ++ document_id), style [ ( "max-width", "100%" ) ] ] []
            ]
        , div [ class "col-md-2" ]
            [ div [ class "btn-group btn-group-justified" ]
                [ div [ class "btn-group-vertical", attribute "role" "group" ]
                    [ button [ type_ "button", class "btn btn-default", classList [ ( "active", (isPreviewActive appState) ) ] ] [ text "Preview" ]
                    , button [ type_ "button", class "btn btn-default", classList [ ( "active", (isDocumentPropertiesActive appState) ) ] ] [ text "Properties" ]
                    ]
                ]
            ]
        ]
