module Views.Document exposing (init, update, view)

import Browser.Navigation as Nav
import Dict
import Factories
import Helpers
import Html exposing (Html)
import Html.Attributes
import Models
import Ports
import String.Format
import Time
import Views.Documents
import Views.Shared



-- Public members


init : () -> Nav.Key -> Models.State -> ( Models.State, Cmd Models.Msg )
init flags keys state =
    let
        ( viewDocumentsState, viewDocumentsCommands ) =
            Views.Documents.init flags keys state Nothing

        ( viewState, viewCommands ) =
            internalUpdate viewDocumentsState
    in
    ( viewState, Cmd.batch [ viewDocumentsCommands, viewCommands ] )


update : Models.State -> ( Models.State, Cmd Models.Msg )
update state =
    internalUpdate state


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
                [ Html.div [ Html.Attributes.class "input-group" ]
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


internalUpdate : Models.State -> ( Models.State, Cmd Models.Msg )
internalUpdate state =
    ( state, Ports.tags { jQueryPath = "#tags" } )
