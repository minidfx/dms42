module Views.Document exposing (init, update, view)

import Browser.Navigation as Nav
import Dict
import Factories
import Helpers
import Html exposing (Html)
import Models



-- Public members


init : () -> Nav.Key -> Models.State -> String -> ( Models.State, Cmd Models.Msg )
init _ _ state documentId =
    internalUpdate state documentId


update : Models.State -> String -> ( Models.State, Cmd Models.Msg )
update state documentId =
    internalUpdate state documentId


view : Models.State -> List (Html Models.Msg)
view state =
    []



-- Private members


internalUpdate : Models.State -> String -> ( Models.State, Cmd Models.Msg )
internalUpdate state documentId =
    let
        documentsState =
            state.documentsState
                |> Maybe.withDefault Factories.documentsStateFactory

        documents =
            documentsState
                |> Helpers.fluentSelect (\x -> x.documents)
                |> Maybe.withDefault Dict.empty

        newDocumentsState =
            { documentsState | document = Dict.get documentId <| documents }
    in
    ( { state | documentsState = Just newDocumentsState }, Cmd.none )
