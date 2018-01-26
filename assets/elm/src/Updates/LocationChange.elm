module Updates.LocationChange exposing (..)

import Routing exposing (..)
import Models.Application exposing (..)
import Navigation exposing (Location)
import Json.Encode as JE exposing (object, int)
import Phoenix.Push
import Phoenix.Socket


dispatch : Location -> Models.Application.AppModel -> ( Models.Application.AppModel, Cmd Models.Application.Msg )
dispatch location model =
    let
        route =
            Routing.parseLocation location
    in
        case route of
            Routing.Documents ->
                let
                    payload =
                        object [ ( "start", int 0 ), ( "length", int 50 ) ]

                    push_ =
                        Phoenix.Push.init "documents" "documents:lobby"
                            |> Phoenix.Push.withPayload payload

                    ( phxSocket, phxCmd ) =
                        Phoenix.Socket.push push_ model.phxSocket
                in
                    ( { model | route = route }, Cmd.map PhoenixMsg phxCmd )

            Routing.Settings ->
                ( { model | route = route }, Cmd.none )

            Routing.Document documentId ->
                ( { model | route = route }, Cmd.none )

            Routing.AddDocuments ->
                ( { model | route = route }, Cmd.none )

            Routing.Home ->
                ( { model | route = route }, Cmd.none )
