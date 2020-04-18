module Views.Document exposing
    ( addTags
    , deleteDocument
    , didDeleteDocument
    , handleDocument
    , init
    , removeTags
    , runOcr
    , runUpdateThumbnails
    , update
    , view
    )

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
import Ports.Gates exposing (tags)
import ScrollTo
import String.Format
import Time
import Views.Documents
import Views.Shared



-- Public members


init : () -> Nav.Key -> Models.State -> String -> ( Models.State, Cmd Models.Msg )
init _ _ state documentId =
    internalUpdate state documentId


update : Models.State -> String -> ( Models.State, Cmd Models.Msg )
update state documentId =
    internalUpdate state documentId


view : Models.State -> String -> Maybe Int -> List (Html Models.Msg)
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
            [ deleteConfirmation state x
            , internalView state x offset
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


handleDocument : Models.State -> Result Http.Error Models.DocumentResponse -> ( Models.State, Cmd Models.Msg )
handleDocument state result =
    let
        documentsState =
            state.documentsState
                |> Maybe.withDefault Factories.documentsStateFactory
    in
    case result of
        Ok x ->
            let
                { id, tags } =
                    x
            in
            ( { state | documentsState = Just { documentsState | documents = Just <| Dict.insert id x <| Maybe.withDefault Dict.empty documentsState.documents } }
            , Views.Shared.getTags
            )

        Err _ ->
            ( state, Cmd.none )


runOcr : Models.DocumentResponse -> Cmd Models.Msg
runOcr { id } =
    Http.post
        { url = "/api/documents/{{ }}/ocr" |> String.Format.value id
        , expect = Http.expectWhatever Models.DidRunOcr
        , body = Http.emptyBody
        }


runUpdateThumbnails : Models.DocumentResponse -> Cmd Models.Msg
runUpdateThumbnails { id } =
    Http.post
        { url = "/api/documents/{{ }}/thumbnails" |> String.Format.value id
        , expect = Http.expectWhatever Models.DidRunUpdateThumbnails
        , body = Http.emptyBody
        }



-- Private members


getDocument : String -> Cmd Models.Msg
getDocument documentId =
    Http.get
        { url =
            "/api/documents/{{ }}"
                |> String.Format.value documentId
        , expect = Http.expectJson Models.GotDocument Views.Documents.documentDecoder
        }


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
                [ Bootstrap.Button.outlineSecondary
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


internalView : Models.State -> Models.DocumentResponse -> Maybe Int -> Html Models.Msg
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
            [ Html.div [ Html.Attributes.class "col-md-7" ] (documentView document offset)
            , Html.div [ Html.Attributes.class "col-md-5" ]
                [ Html.div [ Html.Attributes.class "d-flex document-buttons" ]
                    [ Html.div [ Html.Attributes.class "d-none d-md-block ml-auto" ]
                        [ Bootstrap.Button.button
                            [ Bootstrap.Button.danger
                            , Bootstrap.Button.onClick Models.ShowModal
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
                                    , Html.Events.onClick <| Models.RunOcr document
                                    ]
                                    [ Html.text "Update OCR" ]
                                , Html.button
                                    [ Html.Attributes.class "dropdown-item"
                                    , Html.Events.onClick <| Models.RunUpdateThumbnails document
                                    ]
                                    [ Html.text "Update thumbnails" ]
                                , Html.button
                                    [ Html.Attributes.class "dropdown-item"
                                    , Html.Events.onClick <| Models.RunUpdateAll document
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
                , Views.Shared.tagsinputs tags False
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


documentView : Models.DocumentResponse -> Maybe Int -> List (Html Models.Msg)
documentView document offset =
    let
        { original_file_name, id, thumbnails } =
            document

        { countImages } =
            thumbnails
    in
    case countImages > 1 of
        True ->
            [ pagination document offset
            , Html.img
                [ Html.Attributes.alt original_file_name
                , Html.Attributes.src
                    ("/documents/{{ id }}/images/{{ image_id }}"
                        |> String.Format.namedValue "id" id
                        |> (String.Format.namedValue "image_id" <| String.fromInt <| Maybe.withDefault 0 offset)
                    )
                , Html.Attributes.class "img-fluid img-thumbnail"
                ]
                []
            , pagination document offset
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
                ]
                []
            ]


pagination : Models.DocumentResponse -> Maybe Int -> Html Models.Msg
pagination { thumbnails, id } offset =
    let
        { countImages } =
            thumbnails
    in
    Views.Shared.pagination
        countImages
        1
        offset
        (\x -> "/documents/{{ documentId }}?offset={{ offset }}" |> String.Format.namedValue "documentId" id |> (String.Format.namedValue "offset" <| String.fromInt x))


internalUpdate : Models.State -> String -> ( Models.State, Cmd Models.Msg )
internalUpdate state documentId =
    ( state
    , Cmd.batch
        [ getDocument documentId
        , Cmd.map Models.ScrollToMsg <| ScrollTo.scrollToTop
        ]
    )
