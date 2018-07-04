module Main exposing (..)

import Html exposing (Html)
import Http
import Control
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
import Bootstrap.Modal


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

        Models.FetchDocument document_id ->
            let
                payload =
                    Json.Encode.object
                        [ ( "document_id", Json.Encode.string document_id )
                        ]

                push_ =
                    Phoenix.Push.init "document:get" "documents:lobby"
                        |> Phoenix.Push.withPayload payload

                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.push push_ state.phxSocket
            in
                ( { state | phxSocket = phxSocket }, Cmd.map Models.PhoenixMsg phxCmd )

        Models.CloseModal ->
            ( { state | modalState = Bootstrap.Modal.hidden }, Cmd.none )

        Models.ShowModal ->
            ( { state | modalState = Bootstrap.Modal.shown }, Cmd.none )

        Models.DeleteDocument document_id ->
            let
                request =
                    Http.request
                        { method = "DELETE"
                        , url = "api/documents/" ++ document_id
                        , body = Http.emptyBody
                        , timeout = Nothing
                        , headers = []
                        , expect = Http.expectStringResponse (\{ body } -> (Json.Decode.decodeString (Json.Decode.field "document_id" Json.Decode.string) body))
                        , withCredentials = False
                        }
            in
                ( state, Http.send Models.DocumentDeleted request )

        Models.DocumentDeleted (Ok document_id) ->
            let
                documents =
                    Helpers.removeDocument state.documents document_id

                newState =
                    { state | documents = Just documents }
            in
                ( newState
                , Cmd.batch
                    [ Helpers.sendMsg Models.CloseModal
                    , Navigation.newUrl "#documents"
                    ]
                )

        Models.DocumentDeleted (Err _) ->
            ( { state | error = Just "An error occurred to delete the document." }, Helpers.sendMsg Models.CloseModal )

        Models.ReceiveInitialLoad raw ->
            case Json.Decode.decodeValue JsonDecoders.initialLoadDecoder raw of
                Ok x ->
                    ( { state
                        | documentTypes = Just x.documentTypes
                        , documents = Just (Helpers.mergeDocuments x.documents state.documents)
                      }
                    , Cmd.none
                    )

                Err error ->
                    let
                        _ =
                            Debug.log "Error" error
                    in
                        ( state, Cmd.none )

        Models.Search query ->
            let
                payload =
                    Json.Encode.object
                        [ ( "query", Json.Encode.string query )
                        ]

                push_ =
                    Phoenix.Push.init "documents:search" "documents:lobby"
                        |> Phoenix.Push.withPayload payload

                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.push push_ state.phxSocket
            in
                ( { state | phxSocket = phxSocket, searchQuery = Just query }, Cmd.map Models.PhoenixMsg phxCmd )

        Models.ChangeDocumentsPage page ->
            ( state, Cmd.none )

        Models.ChangeDocumentPage document_id page ->
            let
                newState =
                    case Helpers.getDocument state document_id of
                        Nothing ->
                            state

                        Just x ->
                            let
                                { thumbnails } =
                                    x

                                newThumbnails =
                                    { thumbnails | currentImage = Just page }

                                newDocument =
                                    { x | thumbnails = newThumbnails }
                            in
                                { state | documents = Just (Helpers.mergeDocument state.documents newDocument) }
            in
                ( newState, Cmd.none )

        Models.Debouncer control ->
            Control.update (\x -> { state | debouncer = x }) state.debouncer control

        Models.ReceiveNewDocument raw ->
            case Json.Decode.decodeValue JsonDecoders.documentDecoder raw of
                Ok x ->
                    ( { state | documents = Just (Helpers.mergeDocument state.documents x) }, Cmd.none )

                Err error ->
                    ( { state | error = Just error }, Cmd.none )

        Models.ReceiveSearchResult raw ->
            case Json.Decode.decodeValue JsonDecoders.searchResultDecoder raw of
                Ok x ->
                    let
                        { searchQuery } =
                            state

                        result =
                            case Helpers.safeValue searchQuery "" of
                                "" ->
                                    Nothing

                                _ ->
                                    Just x.result
                    in
                        ( { state | searchResult = result }, Cmd.none )

                Err error ->
                    ( { state | error = Just error }, Cmd.none )

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
                    case Helpers.getDocument state document_id of
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
