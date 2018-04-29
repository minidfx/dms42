module Updates.LocationChange exposing (..)

import Routing exposing (..)
import Models exposing (AppState, Msg, Msg(..))
import Navigation exposing (Location)
import Json.Encode as JE exposing (object, int)
import Phoenix.Push exposing (withPayload)
import Phoenix.Socket exposing (push)
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
                    document =
                        case model.documents of
                            Just x ->
                                Dict.get documentId x

                            Nothing ->
                                Nothing

                    command =
                        case document of
                            Just x ->
                                fetchDocument documentId

                            Nothing ->
                                Cmd.none
                in
                    ( { model | route = route }, command )

            Routing.DocumentProperties documentId ->
                ( { model | route = route }, Cmd.none )

            Routing.AddDocuments ->
                ( { model | route = route }, Cmd.none )

            Routing.Home ->
                ( { model | route = route }, Cmd.none )
