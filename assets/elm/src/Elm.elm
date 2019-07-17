module Main exposing (init, main, subscriptions, update, view)

import AddDocumentView
import Bootstrap.Modal
import Control
import Debug
import Dict
import DocumentView
import DocumentsView
import Helpers
import HomeView
import Html exposing (Html)
import Http
import Json.Decode
import Json.Encode
import JsonDecoders
import Models
import Navigation
import PageView
import Phoenix.Channel
import Phoenix.Push
import Phoenix.Socket
import Ports
import Routing
import SettingsView
import String
import Task


init : Navigation.Location -> ( Models.AppState, Cmd Models.Msg )
init location =
    let
        currentRoute =
            Routing.parseLocation location

        initialState =
            Models.initialModel location currentRoute

        { documentsOffset, documentsLength } =
            initialState

        commands =
            case currentRoute of
                Routing.Document did ->
                    case Helpers.getDocument initialState did of
                        Nothing ->
                            [ Helpers.sendMsg <| Models.FetchDocument did ]

                        _ ->
                            [ Cmd.none ]

                Routing.Documents ->
                    [ Helpers.sendMsg <| Models.FetchDocuments documentsOffset documentsLength
                    ]

                Routing.AddDocuments ->
                    [ Helpers.sendMsg <| Models.FetchDocumentTypes
                    ]

                _ ->
                    []
    in
    ( initialState, Cmd.batch (Helpers.sendMsg Models.JoinChannel :: commands) )


subscriptions : Models.AppState -> Sub Models.Msg
subscriptions state =
    Sub.batch
        [ Phoenix.Socket.listen state.phxSocket Models.PhoenixMsg
        , Ports.newTag Models.NewTag
        , Ports.deleteTag Models.DeleteTag
        ]


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
            PageView.view state SettingsView.view


update : Models.Msg -> Models.AppState -> ( Models.AppState, Cmd Models.Msg )
update msg state =
    case msg of
        Models.OnLocationChange location ->
            let
                route =
                    Routing.parseLocation location
            in
            case route of
                Routing.AddDocuments ->
                    ( { state | route = route }
                    , Helpers.sendMsg <| Models.FetchDocumentTypes
                    )

                Routing.Documents ->
                    let
                        { documentsOffset, documentsLength } =
                            state
                    in
                    ( { state | route = route }
                    , Helpers.sendMsg <| Models.FetchDocuments documentsOffset documentsLength
                    )

                Routing.Document did ->
                    case Helpers.getDocument state did of
                        Nothing ->
                            ( { state | route = route }, Helpers.sendMsg <| Models.FetchDocument did )

                        _ ->
                            ( { state | route = route }, Cmd.none )

                Routing.Home ->
                    let
                        { searchQuery } =
                            state
                    in
                    case searchQuery of
                        Nothing ->
                            ( { state | route = route }, Cmd.none )

                        Just x ->
                            ( { state | route = route }, Helpers.sendMsg <| Models.Search x )

                _ ->
                    ( { state | route = route }, Cmd.none )

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

        Models.FetchDocumentTypes ->
            let
                uri =
                    "/api/document-types"
            in
            ( state
            , Http.send Models.ReceiveDocumentTypes <| Http.get uri JsonDecoders.documentTypesDecoder
            )

        Models.FetchDocuments offset length ->
            let
                uri =
                    "/api/documents?offset=" ++ toString offset ++ "&length=" ++ toString length
            in
            ( state
            , Http.send Models.ReceiveNewDocuments <| Http.get uri JsonDecoders.documentsDecoder
            )

        Models.CloseModal modalId ->
            ( Helpers.addOrUpdateModalState modalId Bootstrap.Modal.hidden state, Cmd.none )

        Models.ShowModal modalId ->
            ( Helpers.addOrUpdateModalState modalId Bootstrap.Modal.shown state, Cmd.none )

        Models.DeleteDocument document_id ->
            let
                request =
                    Http.request
                        { method = "DELETE"
                        , url = "api/documents/" ++ document_id
                        , body = Http.emptyBody
                        , timeout = Nothing
                        , headers = []
                        , expect = Http.expectStringResponse (\{ body } -> Json.Decode.decodeString (Json.Decode.field "document_id" Json.Decode.string) body)
                        , withCredentials = False
                        }
            in
            ( state, Http.send Models.DocumentDeleted request )

        Models.DocumentDeleted (Ok document_id) ->
            let
                documents =
                    Helpers.removeDocument state.documents document_id

                searchResult =
                    Helpers.removeDocument2 state.searchResult document_id

                newState =
                    { state | documents = Just documents, searchResult = Just searchResult }
            in
            ( newState
            , Cmd.batch
                [ Helpers.sendMsg (Models.CloseModal "deleteDocument")
                , Navigation.newUrl "#documents"
                ]
            )

        Models.DocumentDeleted (Err _) ->
            ( { state | error = Just "An error occurred to delete the document." }, Helpers.sendMsg (Models.CloseModal "deleteDocument") )

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
            ( { state | phxSocket = phxSocket, searchQuery = Just query }
            , Cmd.map Models.PhoenixMsg phxCmd
            )

        Models.ChangeDocumentsPage page ->
            let
                { documentsLength } =
                    state

                offset =
                    page * documentsLength
            in
            ( { state | documentsOffset = offset }, Helpers.sendMsg <| Models.FetchDocuments offset documentsLength )

        Models.ChangeDocumentPage document_id page ->
            let
                newStateResult =
                    state
                        |> Helpers.updateDocumentProperties
                            document_id
                            (\x ->
                                let
                                    { thumbnails } =
                                        x
                                in
                                { x | thumbnails = { thumbnails | currentImage = Just page } }
                            )
            in
            case newStateResult of
                Err _ ->
                    ( state, Cmd.none )

                Ok x ->
                    ( x, Cmd.none )

        Models.Debouncer control ->
            Control.update (\x -> { state | debouncer = x }) state.debouncer control

        Models.ReceiveNewTags raw ->
            case Json.Decode.decodeValue JsonDecoders.tagDecoder raw of
                Ok x ->
                    let
                        { document_id, tags } =
                            x
                    in
                    case Helpers.updateDocumentProperties document_id (\x -> { x | tags = tags }) state of
                        Err error ->
                            ( { state | error = Just error }, Cmd.none )

                        Ok x ->
                            ( x, Cmd.none )

                Err error ->
                    ( { state | error = Just error }, Cmd.none )

        Models.ReceiveNewDocument raw ->
            case Json.Decode.decodeValue JsonDecoders.documentDecoder raw of
                Ok x ->
                    ( { state | documents = Just (Helpers.mergeDocument state.documents x) }, Cmd.none )

                Err error ->
                    ( { state | error = Just error }, Cmd.none )

        Models.ReceiveNewDocuments (Ok result) ->
            let
                { documents, total } =
                    result
            in
            ( { state | documents = Just (documents |> Helpers.documentsToDict), documentsCount = total }
            , Cmd.none
            )

        Models.ReceiveNewDocuments (Err _) ->
            ( { state | error = Just "Cannot fetch documents from the server." }, Cmd.none )

        Models.ReceiveDocumentTypes (Ok result) ->
            ( { state | documentTypes = Just result }
            , Cmd.none
            )

        Models.ReceiveDocumentTypes (Err _) ->
            ( { state | error = Just "Cannot fetch document types from the server." }, Cmd.none )

        Models.ReceiveSearchResult raw ->
            case Json.Decode.decodeValue JsonDecoders.searchResultDecoder raw of
                Ok x ->
                    let
                        { searchQuery } =
                            state

                        result =
                            case Maybe.withDefault "" searchQuery of
                                "" ->
                                    Nothing

                                _ ->
                                    Just x.documents
                    in
                    ( { state | searchResult = result }, Cmd.none )

                Err error ->
                    ( { state | error = Just error }, Cmd.none )

        Models.ReceiveOcr raw ->
            case Json.Decode.decodeValue JsonDecoders.ocrResultDecoder raw of
                Ok x ->
                    let
                        { document_id, ocr } =
                            x
                    in
                    case state |> Helpers.updateDocumentProperties document_id (\y -> { y | ocr = Just ocr }) of
                        Err _ ->
                            ( state, Cmd.none )

                        Ok x ->
                            ( x, Cmd.none )

                Err error ->
                    ( state, Cmd.none )

        Models.ReceiveComments raw ->
            case Json.Decode.decodeValue JsonDecoders.commentsResultDecoder raw of
                Ok x ->
                    let
                        { document_id, comments, updated_datetime } =
                            x
                    in
                    case
                        state
                            |> Helpers.updateDocumentProperties
                                document_id
                                (\y ->
                                    let
                                        { datetimes } =
                                            y
                                    in
                                    { y
                                        | comments = Maybe.withDefault Nothing (Just comments)
                                        , datetimes = { datetimes | updated_datetime = Just updated_datetime }
                                    }
                                )
                    of
                        Err x ->
                            ( { state | error = Just x }, Cmd.none )

                        Ok x ->
                            ( x, Cmd.none )

                Err error ->
                    ( { state | error = Just error }, Cmd.none )

        Models.UpdateDocumentComments document_id comments ->
            let
                payload =
                    Json.Encode.object
                        [ ( "comments", Json.Encode.string comments )
                        , ( "document_id", Json.Encode.string document_id )
                        ]

                push_ =
                    Phoenix.Push.init "document:comments" "documents:lobby"
                        |> Phoenix.Push.withPayload payload

                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.push push_ state.phxSocket
            in
            ( { state | phxSocket = phxSocket }, Cmd.map Models.PhoenixMsg phxCmd )

        Models.ProcessOcr document_id ->
            let
                payload =
                    Json.Encode.object
                        [ ( "document_id", Json.Encode.string document_id )
                        ]

                push_ =
                    Phoenix.Push.init "document:ocr" "documents:lobby"
                        |> Phoenix.Push.withPayload payload

                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.push push_ state.phxSocket
            in
            ( { state | phxSocket = phxSocket }
            , Cmd.batch
                [ Cmd.map Models.PhoenixMsg phxCmd
                , Helpers.sendMsg <| Models.ShowModal "ocrSent"
                ]
            )

        Models.JoinChannel ->
            let
                channel =
                    Phoenix.Channel.init "documents:lobby"

                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.join channel state.phxSocket
            in
            ( { state | phxSocket = phxSocket }, Cmd.batch [ Cmd.map Models.PhoenixMsg phxCmd ] )

        Models.NewTag ( tag, document_id ) ->
            let
                payload =
                    Json.Encode.object
                        [ ( "tag", Json.Encode.string tag )
                        , ( "document_id", Json.Encode.string document_id )
                        ]

                push_ =
                    Phoenix.Push.init "document:new_tag" "documents:lobby"
                        |> Phoenix.Push.withPayload payload

                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.push push_ state.phxSocket
            in
            ( { state | phxSocket = phxSocket }, Cmd.map Models.PhoenixMsg phxCmd )

        Models.DeleteTag ( tag, document_id ) ->
            let
                payload =
                    Json.Encode.object
                        [ ( "tag", Json.Encode.string tag )
                        , ( "document_id", Json.Encode.string document_id )
                        ]

                push_ =
                    Phoenix.Push.init "document:delete_tag" "documents:lobby"
                        |> Phoenix.Push.withPayload payload

                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.push push_ state.phxSocket
            in
            ( { state | phxSocket = phxSocket }, Cmd.map Models.PhoenixMsg phxCmd )

        Models.PhoenixMsg msg ->
            let
                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.update msg state.phxSocket
            in
            ( { state | phxSocket = phxSocket }, Cmd.map Models.PhoenixMsg phxCmd )

        Models.ProcessAllThumbnails ->
            ( state, Helpers.sendMsg <| Models.ShowModal "processAllThumnails" )


main : Program Never Models.AppState Models.Msg
main =
    Navigation.program Models.OnLocationChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
