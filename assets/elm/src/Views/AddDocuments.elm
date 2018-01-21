module Views.AddDocuments exposing (..)

import Html exposing (Html, Attribute, div, h1, text, input, h3, select, option, span, node)
import Html.Lazy exposing (..)
import Html.Attributes exposing (class, classList, src, href, title, id, value, selected, type_)
import Models.Application exposing (..)
import Html.Events exposing (on)
import Json.Decode as Json
import Models.Msgs exposing (..)


script : String -> Html Msg
script code =
    node "script" [ type_ "text/javascript" ] [ text code ]


index : Models.Application.AppModel -> Html Msg
index model =
    div []
        [ div [ class "row" ]
            [ div [ class "col-md-6" ]
                [ h3 [] [ text "Document type" ]
                , select [ class "form-control" ] (documentTypeOptions (List.reverse model.documentTypes) [])
                ]
            , div [ class "col-md-6" ]
                [ h3 [] [ text "Tags" ]
                , div [ class "input-group" ]
                    [ input [ class "form-control form-tags" ] []
                    , span [ class "input-group-addon" ]
                        [ span [ class "glyphicon glyphicon-list-alt" ] []
                        ]
                    ]
                ]
            , lazy (\a -> script "$(\"input.form-tags\").tokenfield();") model
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
            , lazy (\a -> script "$(\"div.dropzone\").dropzone({url: \"/api/documents\"});") model
            ]
        ]


documentTypeOptions : List DocumentType -> List (Html Msg) -> List (Html Msg)
documentTypeOptions documentTypes acc =
    case documentTypes of
        [] ->
            acc

        { name, id, selected } :: tail ->
            documentTypeOptions tail ((option [ value id, Html.Attributes.selected selected ] [ text name ]) :: acc)
