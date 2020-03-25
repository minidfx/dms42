module AddDocuments exposing (..)

import Browser.Navigation as Nav
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Models
import Ports


init : () -> Nav.Key -> Models.State -> ( Models.State, Cmd Models.Msg )
init _ _ initialState =
    ( initialState
    , Cmd.batch
        [ Ports.dropZone { jQueryPath = "div.dropzone", jQueryTagsPath = "#tags" }
        , Ports.tags { jQueryPath = "#tags", existingTags = [ "jocelyne", "benjamin" ] }
        ]
    )


update : Models.State -> ( Models.State, Cmd Models.Msg )
update state =
    ( state
    , Cmd.batch
        [ Ports.dropZone { jQueryPath = "div.dropzone", jQueryTagsPath = "#tags" }
        , Ports.tags { jQueryPath = "#tags", existingTags = [ "jocelyne", "benjamin" ] }
        ]
    )


startUpload : Cmd Models.Msg
startUpload =
    Ports.upload { jQueryPath = "div.dropzone" }


view : Models.State -> Html Models.Msg
view { uploading } =
    Html.div []
        [ Html.div [ Html.Attributes.class "row", Html.Attributes.style "margin-bottom" "20px" ]
            [ Html.div [ Html.Attributes.class "col" ]
                [ Html.div [ Html.Attributes.class "dropzone needsclick dz-clickable" ]
                    [ Html.div [ Html.Attributes.class "dz-message needsclick" ]
                        [ Html.i [ Html.Attributes.class "fa fa-file-download" ] []
                        ]
                    ]
                ]
            ]
        , Html.div [ Html.Attributes.class "row", Html.Attributes.style "margin-bottom" "20px" ]
            [ Html.div [ Html.Attributes.class "col" ]
                [ Html.input
                    [ Html.Attributes.type_ "text"
                    , Html.Attributes.class "form-control typeahead"
                    , Html.Attributes.id "tags"
                    , Html.Attributes.attribute "data-role" "tagsinput"
                    ]
                    []
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
                        , Html.Attributes.disabled uploading
                        ]
                        [ Html.i [ Html.Attributes.class "fa fa-cloud-upload-alt" ]
                            []
                        ]
                    ]
                ]
            ]
        ]
