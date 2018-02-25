module Updates.LocationChange exposing (..)

import Routing exposing (..)
import Models exposing (AppState, Msg, Msg(..))
import Navigation exposing (Location)
import Json.Encode as JE exposing (object, int)
import Phoenix.Push exposing (withPayload)
import Phoenix.Socket exposing (push)
import Debug exposing (log)
import Updates.Documents exposing (fetchDocuments)
import Updates.Document exposing (updateDocument)
import Ports.Document exposing (setTokens)
import Debug exposing (log)


dispatch : Location -> AppState -> ( AppState, Cmd Msg )
dispatch location model =
    let
        route =
            Routing.parseLocation (log "location" location)
    in
        case route of
            Routing.Documents ->
                ( { model | route = route }, fetchDocuments 0 50 )

            Routing.Settings ->
                ( { model | route = route }, Cmd.none )

            Routing.Document documentId ->
                let
                    setTokensCmd =
                        setTokens [ "tag1" ]
                in
                    ( { model | route = route }, setTokensCmd )

            Routing.DocumentProperties documentId ->
                ( { model | route = route }, Cmd.none )

            Routing.AddDocuments ->
                ( { model | route = route }, Cmd.none )

            Routing.Home ->
                ( { model | route = route }, Cmd.none )
