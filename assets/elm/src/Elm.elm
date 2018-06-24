module Main exposing (..)

import Html exposing (Html)
import Http
import Models
import Routing
import Navigation
import Debug
import Json.Encode
import Json.Decode
import String
import Ports
import Dict
import PageView
import HomeView
import DocumentsView
import DocumentView
import AddDocumentView
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Task
import Helpers
import JsonDecoders
import Debug
import Debouncer.Basic


init : Navigation.Location -> ( Models.AppState, Cmd Models.Msg )
init location =
    let
        currentRoute =
            Routing.parseLocation location

        initialState =
            Models.initialModel currentRoute
    in
        ( initialState, Helpers.sendMsg Models.JoinChannel )


subscriptions : Models.AppState -> Sub Models.Msg
subscriptions state =
    Phoenix.Socket.listen state.phxSocket Models.PhoenixMsg


view : Models.AppState -> Html Models.Msg
view state =
    case state.route of
        Routing.Home ->
            PageView.view state HomeView.view

        Routing.AddDocuments ->
            PageView.view state AddDocumentView.view

        Routing.Document documentId ->
            PageView.view state (\x -> DocumentView.view x documentId)

        Routing.DocumentProperties documentId ->
            PageView.view state (\x -> DocumentView.view x documentId)

        Routing.Documents ->
            PageView.view state DocumentsView.view

        Routing.Settings ->
            PageView.view state (\x -> Html.div [] [])


update : Models.Msg -> Models.AppState -> ( Models.AppState, Cmd Models.Msg )
update msg state =
    case msg of
        Models.OnLocationChange location ->
            ( { state | route = Routing.parseLocation location }, Cmd.none )

        Models.ReceiveInitialLoad raw ->
            case Json.Decode.decodeValue JsonDecoders.initialLoadDecoder raw of
                Ok x ->
                    ( { state | documentTypes = Just x.documentTypes, documents = Just (Helpers.mergeDocuments x.documents state.documents) }, Cmd.none )

                Err error ->
                    let
                        _ =
                            Debug.log "Error" error
                    in
                        ( state, Cmd.none )

        Models.ReceiveNewDocument raw ->
            case Json.Decode.decodeValue JsonDecoders.documentDecoder raw of
                Ok x ->
                    ( { state | documents = Just (Helpers.mergeDocument state.documents x) }, Cmd.none )

                Err error ->
                    ( state, Cmd.none )

        Models.ReceiveUpdateDocument raw ->
            case Json.Decode.decodeValue JsonDecoders.documentDecoder raw of
                Ok x ->
                    ( { state | documents = Just (Helpers.mergeDocument state.documents x) }, Cmd.none )

                Err error ->
                    ( state, Cmd.none )

        Models.JoinChannel ->
            let
                channel =
                    Phoenix.Channel.init "documents:lobby"

                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.join channel state.phxSocket
            in
                ( { state | phxSocket = phxSocket }, Cmd.batch [ Cmd.map Models.PhoenixMsg phxCmd ] )

        Models.PhoenixMsg msg ->
            let
                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.update msg state.phxSocket
            in
                ( { state | phxSocket = phxSocket }, Cmd.map Models.PhoenixMsg phxCmd )

        Models.UpdateDocumentComments document_id comments ->
            let
                newState =
                    case document_id |> Helpers.getDocument state of
                        Nothing ->
                            state

                        Just x ->
                            { state | documents = Just (Helpers.mergeDocument state.documents { x | comments = Just comments }) }

                payload =
                    Json.Encode.object
                        [ ( "comments", Json.Encode.string comments )
                        , ( "document_id", Json.Encode.string document_id )
                        ]

                push_ =
                    Phoenix.Push.init "document:comments" "documents:lobby"
                        |> Phoenix.Push.withPayload payload

                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.push push_ newState.phxSocket
            in
                ( { newState | phxSocket = phxSocket }, Cmd.map Models.PhoenixMsg phxCmd )


main : Program Never Models.AppState Models.Msg
main =
    Navigation.program Models.OnLocationChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
