module Views.Document exposing (init, update, view)

import Browser.Navigation as Nav
import Dict
import Factories
import Helpers
import Html exposing (Html)
import Html.Attributes
import Models
import String.Format
import Views.Documents



-- Public members


init : () -> Nav.Key -> Models.State -> ( Models.State, Cmd Models.Msg )
init flags keys state =
    let
        ( viewDocumentsState, viewDocumentsCommands ) =
            Views.Documents.init flags keys state

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
            internalView state x

        Nothing ->
            [ Html.div [] [ Html.text "Document not found!" ] ]



-- Private members


internalView : Models.State -> Models.DocumentResponse -> List (Html Models.Msg)
internalView state { id, original_file_name } =
    [ Html.img
        [ Html.Attributes.alt original_file_name
        , Html.Attributes.src
            ("/documents/{{ id }}/images/{{ image_id }}"
                |> String.Format.namedValue "id" id
                |> (String.Format.namedValue "image_id" <| String.fromInt 0)
            )
        , Html.Attributes.class "img-fluid"
        ]
        []
    ]


internalUpdate : Models.State -> ( Models.State, Cmd Models.Msg )
internalUpdate state =
    ( state, Cmd.none )
