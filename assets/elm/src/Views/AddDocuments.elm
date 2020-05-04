module Views.AddDocuments exposing (init, update, view)

import Browser.Navigation as Nav
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Models
import Msgs.AddDocument
import Msgs.Home
import Msgs.Main
import Ports.Gates
import Views.Shared



-- Public members


init : () -> Nav.Key -> Models.State -> Msgs.AddDocument.Msg -> ( Models.State, Cmd Msgs.Main.Msg )
init _ _ initialState msg =
    internalUpdate initialState msg


update : Models.State -> Msgs.AddDocument.Msg -> ( Models.State, Cmd Msgs.Main.Msg )
update state msg =
    internalUpdate state msg


view : Models.State -> List (Html Msgs.Main.Msg)
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
                    , Html.Events.onClick <| Msgs.Main.AddDocumentMsg Msgs.AddDocument.StartUpload
                    , Html.Attributes.disabled isUploading
                    ]
                    [ Html.i [ Html.Attributes.class "fa fa-cloud-upload-alt" ]
                        []
                    ]
                ]
            ]
        ]
    ]



-- Private members


startUpload : Cmd Msgs.Main.Msg
startUpload =
    Ports.Gates.upload { jQueryPath = "div.dropzone", jQueryTagsPath = "#tags" }


internalUpdate : Models.State -> Msgs.AddDocument.Msg -> ( Models.State, Cmd Msgs.Main.Msg )
internalUpdate state msg =
    case msg of
        Msgs.AddDocument.Home ->
            ( state
            , Cmd.batch
                [ Ports.Gates.dropZone { jQueryPath = "div.dropzone", jQueryTagsPath = "#tags" }
                , Views.Shared.getAndLoadTags
                ]
            )

        Msgs.AddDocument.StartUpload ->
            ( { state | isUploading = True }
            , Cmd.batch [ startUpload ]
            )

        Msgs.AddDocument.UploadCompleted ->
            ( { state | isUploading = False }
            , Cmd.none
            )

        Msgs.AddDocument.Nop ->
            ( state, Cmd.none )
