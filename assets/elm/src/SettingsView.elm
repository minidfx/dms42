module SettingsView exposing (view)

import Bootstrap.Button
import Html exposing (Html)
import Html.Attributes
import Models
import SharedViews


generateThumbnailsAlert : Models.AppState -> Html Models.Msg
generateThumbnailsAlert state =
    SharedViews.alert "processAllThumnails" state "Generate all thumbnails sent"


view : Models.AppState -> Html Models.Msg
view state =
    Html.div [ Html.Attributes.class "row" ]
        [ Html.div [ Html.Attributes.class "col" ]
            [ Bootstrap.Button.button
                [ Bootstrap.Button.block
                , Bootstrap.Button.large
                , Bootstrap.Button.dark
                , Bootstrap.Button.onClick Models.ProcessAllThumbnails
                ]
                [ Html.text "Re-generate all thumbnails"
                ]
            , Bootstrap.Button.button
                [ Bootstrap.Button.block
                , Bootstrap.Button.large
                , Bootstrap.Button.dark
                ]
                [ Html.text "OCR all documents"
                ]
            ]
        , Html.div [ Html.Attributes.class "col" ]
            [ Bootstrap.Button.button
                [ Bootstrap.Button.block
                , Bootstrap.Button.large
                , Bootstrap.Button.dark
                ]
                [ Html.text "Export all documents"
                ]
            , Bootstrap.Button.button
                [ Bootstrap.Button.block
                , Bootstrap.Button.large
                , Bootstrap.Button.dark
                ]
                [ Html.text "Background jobs"
                ]
            ]
        ]
