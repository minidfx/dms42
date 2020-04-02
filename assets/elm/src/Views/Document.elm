module Views.Document exposing (addTags, deleteDocument, didDeleteDocument, init, removeTags, update, view)

import Bootstrap.Button
import Bootstrap.Modal
import Browser.Navigation as Nav
import Dict
import Factories
import Helpers
import Html exposing (Html)
import Html.Attributes
import Http
import Models
import Ports.Gates
import String.Format
import Time
import Views.Documents
import Views.Shared



-- Public members


init : () -> Nav.Key -> Models.State -> String -> ( Models.State, Cmd Models.Msg )
init flags keys state documentId =
    let
        ( viewDocumentsState, viewDocumentsCommands ) =
            Views.Documents.init flags keys state Nothing

        ( viewState, viewCommands ) =
            internalUpdate viewDocumentsState documentId
    in
    ( viewState, Cmd.batch [ viewDocumentsCommands, viewCommands ] )


update : Models.State -> String -> ( Models.State, Cmd Models.Msg )
update state documentId =
    internalUpdate state documentId


view : Models.State -> String -> List (Html Models.Msg)
view state documentId =
    let
        documents =
            state.documentsState
                |> Maybe.withDefault Factories.documentsStateFactory
                |> Helpers.fluentSelect (\x -> x.documents)
                |> Maybe.withDefault Dict.empty

        document =
            Dict.get documentId <| documents
    in
    case document of
        Just x ->
            [ deleteConfirmation state x
            , internalView state x
            ]

        Nothing ->
            [ Html.div [] [ Html.text "Document not found!" ] ]


addTags : String -> List String -> Cmd Models.Msg
addTags documentId tags =
    Cmd.batch <|
        (tags
            |> List.map
                (\x ->
                    Http.post
                        { url =
                            "/api/documents/{{ documentId }}/tags/{{ tag }}"
                                |> String.Format.namedValue "documentId" documentId
                                |> String.Format.namedValue "tag" x
                        , body = Http.emptyBody
                        , expect = Http.expectWhatever Models.DidAddTags
                        }
                )
        )


removeTags : String -> List String -> Cmd Models.Msg
removeTags documentId tags =
    Cmd.batch <|
        (tags
            |> List.map
                (\x ->
                    Http.request
                        { method = "DELETE"
                        , headers = []
                        , url =
                            "/api/documents/{{ documentId }}/tags/{{ tag }}"
                                |> String.Format.namedValue "documentId" documentId
                                |> String.Format.namedValue "tag" x
                        , body = Http.emptyBody
                        , expect = Http.expectWhatever Models.DidRemoveTags
                        , timeout = Nothing
                        , tracker = Nothing
                        }
                )
        )


deleteDocument : String -> Cmd Models.Msg
deleteDocument documentId =
    Http.request
        { method = "DELETE"
        , headers = []
        , url =
            "/api/documents/{{ documentId }}"
                |> String.Format.namedValue "documentId" documentId
        , body = Http.emptyBody
        , expect = Http.expectWhatever Models.DidDeleteDocument
        , timeout = Nothing
        , tracker = Nothing
        }


didDeleteDocument : Models.State -> Result Http.Error () -> ( Models.State, Cmd Models.Msg )
didDeleteDocument state _ =
    ( { state | modalVisibility = Bootstrap.Modal.hidden }, Nav.pushUrl state.key "/documents" )



-- Private members


deleteConfirmation : Models.State -> Models.DocumentResponse -> Html Models.Msg
deleteConfirmation { modalVisibility } { id } =
    Bootstrap.Modal.config Models.CloseModal
        |> Bootstrap.Modal.small
        |> Bootstrap.Modal.withAnimation (\x -> Models.AnimatedModal x)
        |> Bootstrap.Modal.hideOnBackdropClick True
        |> Bootstrap.Modal.h5 [] [ Html.text "Confirmation" ]
        |> Bootstrap.Modal.body [] [ Html.text "You are about to delete the document. Are you sure?" ]
        |> Bootstrap.Modal.footer []
            [ Bootstrap.Button.button
                [ Bootstrap.Button.primary
                , Bootstrap.Button.onClick <| Models.AnimatedModal Bootstrap.Modal.hiddenAnimated
                ]
                [ Html.text "Cancel" ]
            , Bootstrap.Button.button
                [ Bootstrap.Button.danger
                , Bootstrap.Button.onClick <| Models.DeleteDocument id
                ]
                [ Html.text "Delete" ]
            ]
        |> Bootstrap.Modal.view modalVisibility


internalView : Models.State -> Models.DocumentResponse -> Html Models.Msg
internalView state { id, original_file_name, tags, datetimes, ocr } =
    let
        { inserted_datetime, original_file_datetime } =
            datetimes

        timeZone =
            Maybe.withDefault Time.utc <| state.userTimeZone
    in
    Html.div [ Html.Attributes.class "document" ]
        [ Html.div [ Html.Attributes.class "row" ]
            []
        , Html.div [ Html.Attributes.class "row" ]
            [ Html.div [ Html.Attributes.class "col-7" ]
                [ Html.img
                    [ Html.Attributes.alt original_file_name
                    , Html.Attributes.src
                        ("/documents/{{ id }}/images/{{ image_id }}"
                            |> String.Format.namedValue "id" id
                            |> (String.Format.namedValue "image_id" <| String.fromInt 0)
                        )
                    , Html.Attributes.class "img-fluid img-thumbnail"
                    ]
                    []
                ]
            , Html.div [ Html.Attributes.class "col" ]
                [ Html.div [ Html.Attributes.class "col-md d-flex document-buttons" ]
                    [ Html.div [ Html.Attributes.class "ml-auto" ]
                        [ Bootstrap.Button.button
                            [ Bootstrap.Button.danger
                            , Bootstrap.Button.onClick Models.ShowModal
                            ]
                            [ Html.text "Delete" ]
                        , Bootstrap.Button.button
                            [ Bootstrap.Button.primary
                            ]
                            [ Html.text "Download" ]
                        ]
                    ]
                , Html.div [ Html.Attributes.class "form-group document-details" ]
                    [ Html.dl []
                        [ Html.dt [] [ Html.text "Document ID" ]
                        , Html.dd [] [ Html.text id ]
                        , Html.dt [] [ Html.text "Uploaded date time" ]
                        , Html.dd [] [ Html.text (Views.Shared.posix2String timeZone inserted_datetime) ]
                        , Html.dt [] [ Html.text "Original date time" ]
                        , Html.dd [] [ Html.text (Views.Shared.posix2String timeZone original_file_datetime) ]
                        ]
                    ]
                , Views.Shared.tagsinputs tags
                ]
            ]
        , Html.div [ Html.Attributes.class "row" ]
            [ Html.div [ Html.Attributes.class "col" ]
                [ Html.div [ Html.Attributes.class "input-group ocr" ]
                    [ Html.div [ Html.Attributes.class "input-group-prepend" ]
                        [ Html.span [ Html.Attributes.class "input-group-text" ] [ Html.text "OCR" ] ]
                    , Html.textarea
                        [ Html.Attributes.class "form-control"
                        , Html.Attributes.attribute "aria-label" "ocr"
                        , Html.Attributes.disabled True
                        ]
                        [ Html.text <| Maybe.withDefault "" ocr ]
                    ]
                ]
            ]
        ]


internalUpdate : Models.State -> String -> ( Models.State, Cmd Models.Msg )
internalUpdate state documentId =
    ( state, Ports.Gates.tags { jQueryPath = "#tags", documentId = Just documentId } )
