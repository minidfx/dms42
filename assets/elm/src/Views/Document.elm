module Views.Document exposing (addTags, init, removeTags, update, view)

import Bootstrap.Button
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
            [ internalView state x ]

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



-- Private members


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
            [ Html.div [ Html.Attributes.class "col-md d-flex" ]
                [ Html.div [ Html.Attributes.class "ml-auto" ]
                    [ Bootstrap.Button.button
                        [ Bootstrap.Button.attrs [ Html.Attributes.class "" ]
                        , Bootstrap.Button.primary
                        ]
                        [ Html.text "Download" ]
                    ]
                ]
            ]
        , Html.div [ Html.Attributes.class "row" ]
            [ Html.div [ Html.Attributes.class "col" ]
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
            ]
        , Html.div [ Html.Attributes.class "row" ]
            [ Html.div [ Html.Attributes.class "col" ]
                [ Html.div [ Html.Attributes.class "form-group" ]
                    [ Html.dl []
                        [ Html.dt [] [ Html.text "Document ID" ]
                        , Html.dd [] [ Html.text id ]
                        , Html.dt [] [ Html.text "Uploaded date time" ]
                        , Html.dd [] [ Html.text (Views.Shared.posix2String timeZone inserted_datetime) ]
                        , Html.dt [] [ Html.text "Original date time" ]
                        , Html.dd [] [ Html.text (Views.Shared.posix2String timeZone original_file_datetime) ]
                        ]
                    ]
                ]
            ]
        , Html.div [ Html.Attributes.class "row" ]
            [ Html.div [ Html.Attributes.class "col" ] [ Views.Shared.tagsinputs tags ] ]
        , Html.div [ Html.Attributes.class "row" ]
            [ Html.div [ Html.Attributes.class "col" ]
                [ Html.div [ Html.Attributes.class "input-group ocr" ]
                    [ Html.div [ Html.Attributes.class "input-group-prepend" ]
                        [ Html.span [ Html.Attributes.class "input-group-text" ] [ Html.text "OCR" ] ]
                    , Html.textarea
                        [ Html.Attributes.class "form-control"
                        , Html.Attributes.attribute "aria-label" "ocr"
                        ]
                        [ Html.text <| Maybe.withDefault "" ocr ]
                    ]
                ]
            ]
        ]


internalUpdate : Models.State -> String -> ( Models.State, Cmd Models.Msg )
internalUpdate state documentId =
    ( state, Ports.Gates.tags { jQueryPath = "#tags", registerEvents = True, documentId = Just documentId } )
