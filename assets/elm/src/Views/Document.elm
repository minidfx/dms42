module Views.Document exposing (..)

import Dict exposing (get)
import Html exposing (Html, div, h1, text, input, img, a, label, textarea, span, button)
import Html.Attributes exposing (class, classList, src, attribute, style, href, type_, id, rows, value, readonly)
import Html.Events exposing (onClick)
import Models exposing (AppState, Msg, Document)
import Routing exposing (Route(Document, DocumentProperties))
import Views.Common exposing (script, rfc2822String)
import Html.Lazy exposing (..)


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


dispatchView : AppState -> Document -> Html Msg
dispatchView appState document =
    let
        { route } =
            appState

        { original_file_name, tags, datetimes, comments, ocr } =
            document

        { original_file_datetime, inserted_datetime, updated_datetime } =
            datetimes

        tags_for_external_js =
            tags |> String.join ","
    in
        case route of
            Routing.Document x ->
                img [ src ("/documents/" ++ x), class "img-thumbnail", style [ ( "max-width", "100%" ) ] ] []

            Routing.DocumentProperties x ->
                div [ class "row" ]
                    [ div [ class "col-md-12" ]
                        [ div [ class "form-group" ]
                            [ label [ attribute "for" "originalFileName" ] [ text "Original file name" ]
                            , input [ type_ "text", class "form-control", id "originalFileName", readonly True, value original_file_name ] []
                            ]
                        , div [ class "form-group" ]
                            [ label [ attribute "for" "originalFileDateTime" ] [ text "Original file date" ]
                            , input [ type_ "text", class "form-control", id "originalFileDateTime", readonly True, value (rfc2822String original_file_datetime) ] []
                            ]
                        , div [ class "form-group" ]
                            [ label [ attribute "for" "uploadDateTime" ] [ text "Upload date" ]
                            , input [ type_ "text", class "form-control", id "uploadDateTime", readonly True, value (rfc2822String inserted_datetime) ] []
                            ]
                        , div [ class "form-group" ]
                            [ div [ class "row" ]
                                [ div [ class "col-md-8" ]
                                    [ label [ attribute "for" "ocr" ] [ text "OCR" ]
                                    , textarea [ class "form-control", id "ocr", rows 10, readonly True ] [ text ocr ]
                                    ]
                                , div [ class "col-md-4", style [ ( "padding-top", "100px" ) ] ]
                                    [ button [ class "btn btn-default", style [ ( "vertical-align", "middle" ) ] ] [ text "Refresh OCR" ]
                                    ]
                                ]
                            ]
                        , div [ class "form-group" ]
                            [ label [ attribute "for" "comments" ] [ text "Comments" ]
                            , textarea [ class "form-control", id "comments", rows 10 ] [ text comments ]
                            ]
                        , div [ class "form-group" ]
                            [ label [ attribute "for" "tags" ] [ text "Tags" ]
                            , div [ class "input-group" ]
                                [ input [ class "form-control form-control-tags", id "editTokensField" ] []
                                , span [ class "input-group-addon" ]
                                    [ span [ class "glyphicon glyphicon-list-alt" ] []
                                    ]
                                ]
                            ]
                        ]
                    , lazy (\a -> script ("loadTokensFields(\"#editTokensField\", '" ++ tags_for_external_js ++ "')")) appState
                    ]

            _ ->
                div [ class "alert alert-warning", attribute "role" "alert" ] [ text "Bad routing!" ]


content : AppState -> String -> Html Msg
content appState documentId =
    let
        { route, documents } =
            appState

        document =
            case documents of
                Just x ->
                    get documentId x

                Nothing ->
                    Nothing
    in
        case document of
            Just x ->
                dispatchView appState x

            Nothing ->
                div [ class "alert alert-warning", attribute "role" "alert" ] [ text "Document unknown!" ]


index : AppState -> String -> Html Msg
index appState documentId =
    div []
        [ div [ class "col-md-10" ]
            [ content appState documentId
            ]
        , div [ class "col-md-2" ]
            [ div [ class "btn-group btn-group-justified" ]
                [ div [ class "btn-group-vertical", attribute "role" "group" ]
                    [ a [ href ("#documents/" ++ documentId), class "btn btn-default", classList [ ( "active", (isPreviewActive appState) ) ] ] [ text "Preview" ]
                    , a [ href ("#documents/" ++ documentId ++ "/properties"), class "btn btn-default", classList [ ( "active", (isDocumentPropertiesActive appState) ) ] ] [ text "Properties" ]
                    ]
                ]
            ]
        ]
