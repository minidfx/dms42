module Views.Document exposing (init, update, view)

import Bootstrap.Button
import Bootstrap.Carousel
import Bootstrap.Carousel.Slide
import Bootstrap.Modal
import Bootstrap.Utilities.Flex
import Bootstrap.Utilities.Spacing
import Browser.Navigation as Nav
import Dict
import Factories
import Helpers
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Http
import Json.Decode
import Models
import Msgs.Document
import Msgs.Main
import ScrollTo
import String.Format
import Task
import Time
import Views.Alerts
import Views.Documents
import Views.Shared



-- Public members


init : () -> Nav.Key -> Models.State -> Msgs.Document.Msg -> Maybe String -> Maybe Int -> ( Models.State, Cmd Msgs.Main.Msg )
init _ _ state msg documentId offset =
    internalUpdate state msg documentId offset


update : Models.State -> Msgs.Document.Msg -> Maybe String -> Maybe Int -> ( Models.State, Cmd Msgs.Main.Msg )
update state msg documentId offset =
    internalUpdate state msg documentId offset


view : Models.State -> String -> Maybe Int -> List (Html Msgs.Main.Msg)
view state documentId offset =
    let
        documents =
            state
                |> Helpers.fluentSelect .documentsState
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
        , expect = Http.expectJson (Msgs.Main.DocumentMsg << Msgs.Document.DidDeleteDocument) didDeleteDocumentDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


didDeleteDocument : Models.State -> Result Http.Error Models.DidDeleteDocumentResponse -> ( Models.State, Cmd Msgs.Main.Msg )
didDeleteDocument state response =
    let
        message =
            case response of
                Ok { documentId } ->
                    String.Format.value documentId <| "Successfully deleted the document {{ }}."

                Err _ ->
                    "Successfully deleted the document."
    in
    ( state
    , Cmd.batch
        [ Views.Alerts.publish { kind = Models.Information, message = message, timeout = Just 5 }
        , Task.succeed Msgs.Main.CloseModal |> Task.perform identity
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
                Just _ ->
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
showDocumentAsModal { modalVisibility, viewPort, carouselState } { id, original_file_name, thumbnails } offset =
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

        documentImageUrl : String -> String
        documentImageUrl imageId =
            "/documents/{{ id }}/images/{{ image_id }}"
                |> String.Format.namedValue "id" id
                |> String.Format.namedValue "image_id" imageId

        slide : String -> Bootstrap.Carousel.Slide.Config Msgs.Main.Msg
        slide imageId =
            Bootstrap.Carousel.Slide.config [] <| Bootstrap.Carousel.Slide.image [] <| documentImageUrl imageId

        slides : List (Bootstrap.Carousel.Slide.Config Msgs.Main.Msg)
        slides =
            thumbnails
                |> Helpers.fluentSelect (\{ countImages } -> countImages - 1)
                |> List.range 0
                |> List.map String.fromInt
                |> List.map slide

        imageContent =
            if List.length slides < 2 then
                [ Html.img
                    [ Html.Attributes.src <| documentImageUrl <| String.fromInt 0
                    , Html.Attributes.class "img-fluid img-thumbnail"
                    ]
                    []
                ]

            else
                case carouselState of
                    Just x ->
                        [ Bootstrap.Carousel.config
                            (Msgs.Main.DocumentMsg << Msgs.Document.CarouselMsg)
                            [ Html.Attributes.alt original_file_name
                            ]
                            |> Bootstrap.Carousel.withIndicators
                            |> Bootstrap.Carousel.withControls
                            |> Bootstrap.Carousel.slides slides
                            |> Bootstrap.Carousel.view x
                        ]

                    Nothing ->
                        [ Html.text "The carousel was not initialized" ]

        modalContent =
            [ Html.div
                [ Bootstrap.Utilities.Flex.block
                , Bootstrap.Utilities.Flex.rowReverse
                , Bootstrap.Utilities.Spacing.mb1
                ]
                [ Bootstrap.Button.button
                    [ Bootstrap.Button.attrs
                        [ Html.Attributes.attribute "aria-label" "Close"
                        ]
                    , Bootstrap.Button.onClick <| Msgs.Main.AnimatedModal Bootstrap.Modal.hiddenAnimated
                    , Bootstrap.Button.outlineDark
                    ]
                    [ Html.i
                        [ Html.Attributes.class "fas fa-times" ]
                        []
                    ]
                ]
            ]
                ++ imageContent
    in
    Bootstrap.Modal.config Msgs.Main.CloseModal
        |> Bootstrap.Modal.withAnimation (\x -> Msgs.Main.AnimatedModal x)
        |> Bootstrap.Modal.hideOnBackdropClick True
        |> Bootstrap.Modal.body [] modalContent
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
                        [ Html.div
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
                                [ Html.Attributes.class "dropdown-menu dropdown-menu-right"
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
                        , Bootstrap.Button.button
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
                , Views.Shared.tagsInputs False
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
    if countImages > 1 then
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

    else
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


internalUpdate : Models.State -> Msgs.Document.Msg -> Maybe String -> Maybe Int -> ( Models.State, Cmd Msgs.Main.Msg )
internalUpdate state msg routeDocumentId offset =
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

                localOffset =
                    Maybe.withDefault 0 offset

                { tagsLoaded } =
                    state

                ( newState, commands ) =
                    case document of
                        Just { id } ->
                            if tagsLoaded then
                                ( state, [] )

                            else
                                ( state, [ Views.Shared.getAndLoadTags ] )

                        Nothing ->
                            case routeDocumentId of
                                Just x ->
                                    ( { state | isLoading = True }, [ getDocument x ] )

                                Nothing ->
                                    ( state, [] )

                carouselStateOptions =
                    Bootstrap.Carousel.defaultStateOptions

                carouselState =
                    Bootstrap.Carousel.initialStateWithOptions { carouselStateOptions | startIndex = localOffset }
            in
            ( { newState | carouselState = Just carouselState }
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

        Msgs.Document.DidRunOcr result ->
            case result of
                Ok _ ->
                    ( state
                    , Cmd.batch
                        [ Views.Alerts.publish
                            { kind = Models.Information
                            , message = "The OCR update on the document was successfully ran."
                            , timeout = Just 5
                            }
                        ]
                    )

                Err _ ->
                    ( state, Cmd.none )

        Msgs.Document.DidRunUpdateThumbnails result ->
            case result of
                Ok _ ->
                    ( state
                    , Cmd.batch
                        [ Views.Alerts.publish
                            { kind = Models.Information
                            , message = "The thumbnails update on the document was successfully ran."
                            , timeout = Just 5
                            }
                        ]
                    )

                Err _ ->
                    ( state, Cmd.none )

        Msgs.Document.RunUpdateAll document ->
            ( state
            , Cmd.batch
                [ runOcr document
                , runUpdateThumbnails document
                ]
            )

        Msgs.Document.CarouselMsg subMsg ->
            let
                { carouselState } =
                    state
            in
            case carouselState of
                Just x ->
                    ( { state | carouselState = Just <| Bootstrap.Carousel.update subMsg x }
                    , Cmd.none
                    )

                Nothing ->
                    ( state, Cmd.none )


didDeleteDocumentDecoder : Json.Decode.Decoder Models.DidDeleteDocumentResponse
didDeleteDocumentDecoder =
    Json.Decode.map Models.DidDeleteDocumentResponse
        (Json.Decode.field "documentId" Json.Decode.string)
