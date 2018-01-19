module Views.AddDocuments exposing (..)

import Html exposing (Html, div, h1, text, input, form, h3)
import Html.Attributes exposing (class, classList, src, href, title, id, enctype, method)
import Models.Application exposing (..)


index : Models.Application.AppModel -> Html msg
index model =
    div []
        [ div [ class "row" ]
            [ div [ class "col-md-12" ]
                [ h3 [] [ text "Tags" ]
                , input [ class "form-control" ] []
                ]
            ]
        , div [ class "row" ]
            [ div [ class "col-md-12" ]
                [ h3 [] [ text "Files" ]
                , div [ id "dropzone" ]
                    [ form [ class "dropzone needsclick dz-clickable", method "post", enctype "multipart/form-data" ]
                        [ div [ class "dz-message needsclick" ]
                            [ text "Drop files here or click to upload."
                            ]
                        ]
                    ]
                ]
            ]
        ]
