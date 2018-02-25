module Views.AddDocuments exposing (..)

import Html exposing (Html, Attribute, div, h1, text, input, h3, select, option, span, node)
import Html.Lazy exposing (..)
import Html.Attributes exposing (class, classList, src, href, title, id, value, selected, type_)
import Models exposing (AppState, Msg, Document, DocumentType)
import Html.Events exposing (on)
import Json.Decode as Json
import Views.Common exposing (script)


index : AppState -> Html Msg
index model =
    div []
        [ div [ class "row" ]
            [ div [ class "col-md-6" ]
                [ h3 [] [ text "Document type" ]
                , select [ class "form-control form-control-document-type" ] (documentTypeOptions (List.reverse model.documentTypes) [])
                ]
            , div [ class "col-md-6" ]
                [ h3 [] [ text "Tags" ]
                , div [ class "input-group" ]
                    [ input [ class "form-control form-control-tags", id "addTokensField" ] []
                    , span [ class "input-group-addon" ]
                        [ span [ class "glyphicon glyphicon-list-alt" ] []
                        ]
                    ]
                ]
            , lazy (\a -> script "loadTokensFields(\"#addTokensField\")") model
            ]
        , div [ class "row" ]
            [ div [ class "col-md-12" ]
                [ h3 [] [ text "Files" ]
                , div []
                    [ div [ class "dropzone needsclick dz-clickable" ]
                        [ div [ class "dz-message needsclick" ]
                            [ span [ class "glyphicon glyphicon-save" ] []
                            , text "Drop here your documents"
                            ]
                        ]
                    ]
                ]
            ]
        , lazy (\a -> script "loadDropZone();") model
        ]


documentTypeOptions : List DocumentType -> List (Html Msg) -> List (Html Msg)
documentTypeOptions documentTypes acc =
    case documentTypes of
        [] ->
            acc

        { name, id } :: tail ->
            documentTypeOptions tail ((option [ value id ] [ text name ]) :: acc)
