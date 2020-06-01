module Views.Document exposing (init, update, view)

import Bootstrap.Button
import Bootstrap.Modal
import Browser.Navigation as Nav
import Dict
import Factories
import Helpers
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Http
import Models
import Msgs.Document
import Msgs.Main
import ScrollTo
import String.Format
import Task
import Time
import Views.Documents
import Views.Shared



-- Public members


init : () -> Nav.Key -> Models.State -> Msgs.Document.Msg -> Maybe String -> ( Models.State, Cmd Msgs.Main.Msg )
init _ _ state msg documentId =
    internalUpdate state msg documentId


update : Models.State -> Msgs.Document.Msg -> Maybe String -> ( Models.State, Cmd Msgs.Main.Msg )
update state msg documentId =
    internalUpdate state msg documentId


view : Models.State -> String -> Maybe Int -> List (Html Msgs.Main.Msg)
view state documentId offset =
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
            [ deleteConfirmationModal state x
            , showDocumentAsModal state x offset
            , internalView state x offset
            ]

        Nothing ->
            [ Html.div [] [ Html.text "Document not found!" ] ]



-- Private members


addTags : String -> List String -> Cmd Msgs.Main.Msg
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
                        , expect = Http.expectWhatever (Msgs.Main.DocumentMsg << Msgs.Document.DidAddTags)
                        }
                )
        )


removeTags : String -> List String -> Cmd Msgs.Main.Msg
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
                        , expect = Http.expectWhatever (Msgs.Main.DocumentMsg << Msgs.Document.DidRemoveTags)
                        , timeout = Nothing
                        , tracker = Nothing
                        }
                )
        )


deleteDocument : String -> Cmd Msgs.Main.Msg
deleteDocument documentId =
    Http.request
        { method = "DELETE"
        , headers = []
        , url =
            "/api/documents/{{ documentId }}"
                |> String.Format.namedValue "documentId" documentId
        , body = Http.emptyBody
        , expect = Http.expectWhatever (Msgs.Main.DocumentMsg << Msgs.Document.DidDeleteDocument)
        , timeout = Nothing
        , tracker = Nothing
        }


didDeleteDocument : Models.State -> Result Http.Error () -> ( Models.State, Cmd Msgs.Main.Msg )
didDeleteDocument state _ =
    ( state
    , Cmd.batch
        [ Task.succeed Msgs.Main.CloseModal |> Task.perform identity
        , Nav.pushUrl state.key "/documents"
        ]
    )


handleDocument : Models.State -> Result Http.Error Models.DocumentResponse -> ( Models.State, Cmd Msgs.Main.Msg )
handleDocument ({ documentsState } as state) result =
    let
        localState =
            { state | isLoading = False }

        localDocumentsState =
            documentsState
                |> Maybe.withDefault Factories.documentsStateFactory
    in
    case result of
        Ok ({ id, tags } as x) ->
            let
                documents =
                    localDocumentsState.documents
                        |> Maybe.withDefault Dict.empty
                        |> Dict.insert id x

                document =
                    documents
                        |> Dict.get id

                newState =
                    { localState | documentsState = Just { localDocumentsState | documents = Just documents } }
            in
            case document of
                Just d ->
                    ( newState, Views.Shared.getAndLoadTags )

                Nothing ->
                    ( newState, Cmd.none )

        Err _ ->
            ( { localState | isLoading = False }, Cmd.none )


runOcr : Models.DocumentResponse -> Cmd Msgs.Main.Msg
runOcr { id } =
    Http.post
        { url = "/api/documents/{{ }}/ocr" |> String.Format.value id
        , expect = Http.expectWhatever (Msgs.Main.DocumentMsg << Msgs.Document.DidRunOcr)
        , body = Http.emptyBody
        }


runUpdateThumbnails : Models.DocumentResponse -> Cmd Msgs.Main.Msg
runUpdateThumbnails { id } =
    Http.post
        { url = "/api/documents/{{ }}/thumbnails" |> String.Format.value id
        , expect = Http.expectWhatever (Msgs.Main.DocumentMsg << Msgs.Document.DidRunUpdateThumbnails)
        , body = Http.emptyBody
        }


getDocument : String -> Cmd Msgs.Main.Msg
getDocument documentId =
    Http.get
        { url =
            "/api/documents/{{ }}"
                |> String.Format.value documentId
        , expect = Http.expectJson (Msgs.Main.DocumentMsg << Msgs.Document.GotDocument) Views.Documents.documentDecoder
        }


deleteConfirmationModal : Models.State -> Models.DocumentResponse -> Html Msgs.Main.Msg
deleteConfirmationModal { modalVisibility } { id } =
    let
        visibility =
            case modalVisibility of
                Just modal ->
                    if modal.id == "deleteDialog" then
                        modal.visibility

                    else
                        Bootstrap.Modal.hidden

                Nothing ->
                    Bootstrap.Modal.hidden
    in
    Bootstrap.Modal.config Msgs.Main.CloseModal
        |> Bootstrap.Modal.small
        |> Bootstrap.Modal.withAnimation (\x -> Msgs.Main.AnimatedModal x)
        |> Bootstrap.Modal.hideOnBackdropClick True
        |> Bootstrap.Modal.h5 [] [ Html.text "Confirmation" ]
        |> Bootstrap.Modal.body [] [ Html.text "You are about to delete the document. Are you sure?" ]
        |> Bootstrap.Modal.footer []
            [ Bootstrap.Button.button
                [ Bootstrap.Button.outlineSecondary
                , Bootstrap.Button.onClick <| Msgs.Main.AnimatedModal Bootstrap.Modal.hiddenAnimated
                ]
                [ Html.text "Cancel" ]
            , Bootstrap.Button.button
                [ Bootstrap.Button.danger
                , Bootstrap.Button.onClick <| (Msgs.Main.DocumentMsg << Msgs.Document.DeleteDocument) <| id
                ]
                [ Html.text "Delete" ]
            ]
        |> Bootstrap.Modal.view visibility


showDocumentAsModal : Models.State -> Models.DocumentResponse -> Maybe Int -> Html Msgs.Main.Msg
showDocumentAsModal { modalVisibility, viewPort } { id, original_file_name } offset =
    let
        visibility =
            case modalVisibility of
                Just modal ->
                    if modal.id == "showDocumentAsModal" then
                        modal.visibility

                    else
                        Bootstrap.Modal.hidden

                Nothing ->
                    Bootstrap.Modal.hidden
    in
    Bootstrap.Modal.config Msgs.Main.CloseModal
        |> Bootstrap.Modal.withAnimation (\x -> Msgs.Main.AnimatedModal x)
        |> Bootstrap.Modal.hideOnBackdropClick True
        |> Bootstrap.Modal.body []
            [ Html.img
                [ Html.Attributes.alt original_file_name
                , Html.Attributes.src
                    ("/documents/{{ id }}/images/{{ image_id }}"
                        |> String.Format.namedValue "id" id
                        |> (String.Format.namedValue "image_id" <| String.fromInt <| Maybe.withDefault 0 offset)
                    )
                , Html.Attributes.class "img-fluid img-thumbnail"
                , Html.Events.onClick <| Msgs.Main.AnimatedModal Bootstrap.Modal.hiddenAnimated
                ]
                []
            ]
        |> Bootstrap.Modal.scrollableBody True
        |> Bootstrap.Modal.centered False
        |> Bootstrap.Modal.attrs [ Html.Attributes.class "showDocumentAsModal" ]
        |> Bootstrap.Modal.view visibility


internalView : Models.State -> Models.DocumentResponse -> Maybe Int -> Html Msgs.Main.Msg
internalView state document offset =
    let
        { id, original_file_name, tags, datetimes, ocr, thumbnails } =
            document

        { inserted_datetime, original_file_datetime } =
            datetimes

        timeZone =
            Maybe.withDefault Time.utc <| state.userTimeZone
    in
    Html.div [ Html.Attributes.class "document" ]
        [ Html.div [ Html.Attributes.class "row" ]
            [ Html.div [ Html.Attributes.class "col-md-7" ] (documentView state document offset)
            , Html.div [ Html.Attributes.class "col-md-5" ]
                [ Html.div [ Html.Attributes.class "d-flex document-buttons" ]
                    [ Html.div [ Html.Attributes.class "d-none d-md-block ml-auto" ]
                        [ Bootstrap.Button.button
                            [ Bootstrap.Button.danger
                            , Bootstrap.Button.onClick <| Msgs.Main.ShowModal "deleteDialog"
                            ]
                            [ Html.text "Delete" ]
                        , Bootstrap.Button.linkButton
                            [ Bootstrap.Button.outlinePrimary
                            , Bootstrap.Button.attrs
                                [ Html.Attributes.href <| ("/api/documents/{{ }}/download" |> String.Format.value id)
                                , Html.Attributes.download ""
                                ]
                            ]
                            [ Html.text "Download" ]
                        , Html.div
                            [ Html.Attributes.class "btn-group"
                            , Html.Attributes.attribute "role" "group"
                            ]
                            [ Html.button
                                [ Html.Attributes.class "btn btn-secondary dropdown-toggle"
                                , Html.Attributes.type_ "button"
                                , Html.Attributes.attribute "data-toggle" "dropdown"
                                , Html.Attributes.attribute "aria-haspopup" "True"
                                , Html.Attributes.attribute "aria-expanded" "False"
                                , Html.Attributes.id "optionsBtn"
                                ]
                                [ Html.text "Options" ]
                            , Html.div
                                [ Html.Attributes.class "dropdown-menu"
                                , Html.Attributes.attribute "aria-labelledby" "optionsBtn"
                                ]
                                [ Html.button
                                    [ Html.Attributes.class "dropdown-item"
                                    , Html.Events.onClick <| (Msgs.Main.DocumentMsg << Msgs.Document.RunOcr) <| document
                                    ]
                                    [ Html.text "Update OCR" ]
                                , Html.button
                                    [ Html.Attributes.class "dropdown-item"
                                    , Html.Events.onClick <| (Msgs.Main.DocumentMsg << Msgs.Document.RunUpdateThumbnails) <| document
                                    ]
                                    [ Html.text "Update thumbnails" ]
                                , Html.button
                                    [ Html.Attributes.class "dropdown-item"
                                    , Html.Events.onClick <| (Msgs.Main.DocumentMsg << Msgs.Document.RunUpdateAll) <| document
                                    ]
                                    [ Html.text "Update all" ]
                                ]
                            ]
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
                        , Html.dt [] [ Html.text "Original file name" ]
                        , Html.dd [] [ Html.text original_file_name ]
                        ]
                    ]
                , Views.Shared.tagsinputs False
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


documentView : Models.State -> Models.DocumentResponse -> Maybe Int -> List (Html Msgs.Main.Msg)
documentView state document offset =
    let
        { original_file_name, id, thumbnails } =
            document

        { countImages } =
            thumbnails
    in
    case countImages > 1 of
        True ->
            [ pagination state document offset
            , Html.img
                [ Html.Attributes.alt original_file_name
                , Html.Attributes.src
                    ("/documents/{{ id }}/images/{{ image_id }}"
                        |> String.Format.namedValue "id" id
                        |> (String.Format.namedValue "image_id" <| String.fromInt <| Maybe.withDefault 0 offset)
                    )
                , Html.Attributes.class "img-fluid img-thumbnail"
                , Html.Events.onClick <| Msgs.Main.ShowModal "showDocumentAsModal"
                ]
                []
            , pagination state document offset
            ]

        False ->
            [ Html.img
                [ Html.Attributes.alt original_file_name
                , Html.Attributes.src
                    ("/documents/{{ id }}/images/{{ image_id }}"
                        |> String.Format.namedValue "id" id
                        |> (String.Format.namedValue "image_id" <| String.fromInt <| Maybe.withDefault 0 offset)
                    )
                , Html.Attributes.class "img-fluid img-thumbnail"
                , Html.Events.onClick <| Msgs.Main.ShowModal "showDocumentAsModal"
                ]
                []
            ]


pagination : Models.State -> Models.DocumentResponse -> Maybe Int -> Html Msgs.Main.Msg
pagination { viewPort } { thumbnails, id } offset =
    let
        { countImages } =
            thumbnails

        localOffset =
            offset |> Maybe.withDefault 0
    in
    Views.Shared.pagination
        viewPort
        countImages
        1
        localOffset
        (\x -> "/documents/{{ documentId }}?offset={{ offset }}" |> String.Format.namedValue "documentId" id |> (String.Format.namedValue "offset" <| String.fromInt x))


internalUpdate : Models.State -> Msgs.Document.Msg -> Maybe String -> ( Models.State, Cmd Msgs.Main.Msg )
internalUpdate state msg routeDocumentId =
    case msg of
        Msgs.Document.ShowDocumentAsModal ->
            ( state, Cmd.none )

        Msgs.Document.Home ->
            let
                document =
                    state.documentsState
                        |> Maybe.andThen (\x -> x.documents)
                        |> Maybe.map2 (\id documents -> Dict.get id documents) routeDocumentId
                        |> Maybe.andThen (\x -> x)

                ( newState, commands ) =
                    case document of
                        Just { id } ->
                            ( { state | isLoading = True }, [ getDocument id ] )

                        Nothing ->
                            case routeDocumentId of
                                Just x ->
                                    ( { state | isLoading = True }, [ getDocument x ] )

                                Nothing ->
                                    ( state, [] )
            in
            ( newState
            , Cmd.batch <| commands ++ [ Cmd.map Msgs.Main.ScrollToMsg <| ScrollTo.scrollToTop ]
            )

        Msgs.Document.GotDocument result ->
            handleDocument state result

        Msgs.Document.AddTags { documentId, tags } ->
            ( state, addTags documentId tags )

        Msgs.Document.RemoveTags { documentId, tags } ->
            ( state, removeTags documentId tags )

        Msgs.Document.DidRemoveTags _ ->
            ( state, Cmd.none )

        Msgs.Document.DidAddTags _ ->
            ( state, Cmd.none )

        Msgs.Document.DeleteDocument documentId ->
            ( state, deleteDocument documentId )

        Msgs.Document.DidDeleteDocument result ->
            didDeleteDocument state result

        Msgs.Document.RunOcr document ->
            ( state, runOcr document )

        Msgs.Document.RunUpdateThumbnails document ->
            ( state, runUpdateThumbnails document )

        Msgs.Document.DidRunOcr _ ->
            ( state, Cmd.none )

        Msgs.Document.DidRunUpdateThumbnails _ ->
            ( state, Cmd.none )

        Msgs.Document.RunUpdateAll document ->
            ( state, Cmd.batch [ runOcr document, runUpdateThumbnails document ] )
