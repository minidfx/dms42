module AddDocumentView exposing (view)

import Html exposing (Html)
import Html.Attributes
import Html.Lazy
import Models
import Helpers
import Bootstrap.Form.Select


view : Models.AppState -> Html Models.Msg
view state =
    let
        documentTypes =
            case state.documentTypes of
                Nothing ->
                    []

                Just x ->
                    x
    in
        Html.div []
            [ Html.div [ Html.Attributes.class "row" ]
                [ Html.div [ Html.Attributes.class "col-md" ]
                    [ Html.div [ Html.Attributes.class "form-group" ]
                        [ Html.label [ Html.Attributes.for "documentTypes" ] [ Html.text "Document types" ]
                        , Bootstrap.Form.Select.select
                            [ Bootstrap.Form.Select.id "documentType" ]
                            (List.map (\x -> Bootstrap.Form.Select.item [ Html.Attributes.value x.id ] [ Html.text x.name ]) documentTypes)
                        ]
                    ]
                , Html.div [ Html.Attributes.class "col-md" ]
                    [ Html.div [ Html.Attributes.class "form-group" ]
                        [ Html.label [ Html.Attributes.for "documentTypes" ] [ Html.text "Tags" ]
                        , Html.input
                            [ Html.Attributes.type_ "text"
                            , Html.Attributes.class "form-control"
                            , Html.Attributes.id "tags"
                            ]
                            []
                        ]
                    ]
                ]
            , Html.div [ Html.Attributes.class "row" ]
                [ Html.div [ Html.Attributes.class "col" ]
                    [ Html.div [ Html.Attributes.class "dropzone needsclick dz-clickable" ]
                        [ Html.div [ Html.Attributes.class "dz-message needsclick" ]
                            [ Html.span [ Html.Attributes.class "fas fa-upload" ] []
                            ]
                        ]
                    ]
                ]
            , Html.Lazy.lazy (\_ -> Helpers.script ("loadDropZone();$('#tags').tagsinput({trimValue: true});")) state
            ]
