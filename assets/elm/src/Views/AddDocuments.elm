module Views.AddDocuments exposing (init, startUpload, update, view)

import Browser.Navigation as Nav
import Helpers
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Models
import Ports.Gates
import Views.Shared



-- Public members


init : () -> Nav.Key -> Models.State -> ( Models.State, Cmd Models.Msg )
init _ _ initialState =
    ( initialState
    , Cmd.batch
        [ Views.Shared.getTags
        , Ports.Gates.dropZone { jQueryPath = "div.dropzone", jQueryTagsPath = "#tags" }
        ]
    )


update : Models.State -> ( Models.State, Cmd Models.Msg )
update state =
    ( state
    , Cmd.batch
        [ Ports.Gates.dropZone { jQueryPath = "div.dropzone", jQueryTagsPath = "#tags" }
        , Views.Shared.getTags
        ]
    )


view : Models.State -> List (Html Models.Msg)
view state =
    let
        { isUploading } =
            state
    in
    [ Html.div [ Html.Attributes.class "row", Html.Attributes.style "margin-bottom" "20px" ]
        [ Html.div [ Html.Attributes.class "col" ]
            [ Html.h4 [] [ Html.text "Documents" ]
            , Html.div [ Html.Attributes.class "dropzone needsclick dz-clickable" ]
                [ Html.div [ Html.Attributes.class "dz-message needsclick" ]
                    [ Html.i [ Html.Attributes.class "fa fa-file-download" ] []
                    ]
                ]
            ]
        ]
    , Html.div [ Html.Attributes.class "row", Html.Attributes.style "margin-bottom" "20px" ]
        [ Html.div [ Html.Attributes.class "col" ]
            [ Html.h4 [] [ Html.text "Tags" ]
            , Views.Shared.tagsinputs isUploading
            ]
        ]
    , Html.div [ Html.Attributes.class "row" ]
        [ Html.div [ Html.Attributes.class "col d-flex" ]
            [ Html.div [ Html.Attributes.class "ml-auto" ]
                [ Html.button
                    [ Html.Attributes.type_ "button"
                    , Html.Attributes.class "btn btn-primary"
                    , Html.Attributes.title "Send the document to the server"
                    , Html.Events.onClick Models.StartUpload
                    , Html.Attributes.disabled isUploading
                    ]
                    [ Html.i [ Html.Attributes.class "fa fa-cloud-upload-alt" ]
                        []
                    ]
                ]
            ]
        ]
    ]


startUpload : Cmd Models.Msg
startUpload =
    Ports.Gates.upload { jQueryPath = "div.dropzone", jQueryTagsPath = "#tags" }



-- Private members
