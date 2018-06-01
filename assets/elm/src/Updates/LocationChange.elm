module Updates.LocationChange exposing (..)

import Routing exposing (..)
import Models exposing (AppState, Msg, Msg(..))
import Navigation exposing (Location)
import Json.Encode as JE exposing (object, int)
import Debug exposing (log)
import Updates.Documents exposing (fetchDocuments, fetchDocumentTypes)
import Updates.Document exposing (fetchDocument)
import Debug exposing (log)
import Dict


dispatch : Location -> AppState -> ( AppState, Cmd Msg )
dispatch location model =
    let
        route =
            Routing.parseLocation (log "location" location)
    in
        case route of
            Routing.Documents ->
                ( { model | route = route }, Cmd.none )

            Routing.Settings ->
                ( { model | route = route }, Cmd.none )

            Routing.Document documentId ->
                let
                    -- Try to find the document by its ID
                    document =
                        case model.documents of
                            Just x ->
                                Dict.get documentId x

                            Nothing ->
                                Nothing

                    -- Try to fetch the document if it is not in the global state
                    command =
                        case document of
                            Just x ->
                                Cmd.none

                            Nothing ->
                                fetchDocument documentId
                in
                    ( { model | route = route, current_page = 0 }, command )

            Routing.DocumentProperties documentId ->
                ( { model | route = route }, Cmd.none )

            Routing.AddDocuments ->
                ( { model | route = route }, Cmd.none )

            Routing.Home ->
                ( { model | route = route }, Cmd.none )
