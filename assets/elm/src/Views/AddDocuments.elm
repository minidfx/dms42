module Views.AddDocuments exposing (..)

import Html exposing (Html, Attribute, div, h1, text, input, h3, select, option, span, node)
import Html.Lazy exposing (..)
import Html.Attributes exposing (class, classList, src, href, title, id, value, selected, type_)
import Models.Application exposing (..)
import Html.Events exposing (on)
import Json.Decode as Json


script : String -> Html Msg
script code =
    node "script" [ type_ "text/javascript" ] [ text code ]


index : Models.Application.AppModel -> Html Msg
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
                    [ input [ class "form-control form-control-tags" ] []
                    , span [ class "input-group-addon" ]
                        [ span [ class "glyphicon glyphicon-list-alt" ] []
                        ]
                    ]
                ]
            , lazy (\a -> script "$(\"input.form-control-tags\").tokenfield();") model
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
            , lazy (\a -> script dropzoneJavascript) model
            ]
        ]


dropzoneJavascript : String
dropzoneJavascript =
    """
$("div.dropzone").dropzone({url: "/api/documents",
                            acceptedFiles: "image/png,image/jpeg,application/pdf",
                            params: getUploadFields,
                            autoProcessQueue: true,
                            parallelUploads: 1000,
                            ignoreHiddenFiles: true,
                            acceptedFiles: "image/*,application/pdf" });
    """


documentTypeOptions : List DocumentType -> List (Html Msg) -> List (Html Msg)
documentTypeOptions documentTypes acc =
    case documentTypes of
        [] ->
            acc

        { name, id } :: tail ->
            documentTypeOptions tail ((option [ value id ] [ text name ]) :: acc)
