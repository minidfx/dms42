module Views.AddDocuments exposing (..)

import Html exposing (Html, div, h1, text, input, h3, select, option, span)
import Html.Attributes exposing (class, classList, src, href, title, id, value, selected)
import Models.Application exposing (..)


index : Models.Application.AppModel -> Html msg
index model =
    div []
        [ div [ class "row" ]
            [ div [ class "col-md-6" ]
                [ h3 [] [ text "Tags" ]
                , div [ class "input-group" ]
                    [ input [ class "form-control" ] []
                    , span [ class "input-group-addon" ]
                        [ span [ class "glyphicon glyphicon-list-alt" ] []
                        ]
                    ]
                ]
            , div [ class "col-md-6" ]
                [ h3 [] [ text "Document type" ]
                , select [ class "form-control" ] (documentTypeOptions (List.reverse model.documentTypes) [])
                ]
            ]
        , div [ class "row" ]
            [ div [ class "col-md-12" ]
                [ h3 [] [ text "Files" ]
                , div [ id "dropzone" ]
                    [ div [ class "dropzone needsclick dz-clickable" ]
                        [ div [ class "dz-message needsclick" ]
                            [ span [ class "glyphicon glyphicon-save" ] []
                            , text "Drop here your documents"
                            ]
                        ]
                    ]
                ]
            ]
        ]


documentTypeOptions : List DocumentType -> List (Html msg) -> List (Html msg)
documentTypeOptions documentTypes acc =
    case documentTypes of
        [] ->
            acc

        { name, id, selected } :: tail ->
            documentTypeOptions tail ((option [ value id, Html.Attributes.selected selected ] [ text name ]) :: acc)
