module Main exposing (..)

import Layout exposing (..)
import Html exposing (Html)
import Http exposing (send)
import Models exposing (AppState, Document, Msg, Msg(..), initialModel)
import Routing exposing (..)
import Navigation exposing (Location, newUrl)
import Views.Home exposing (..)
import Views.Documents exposing (..)
import Views.Document exposing (..)
import Views.Settings exposing (..)
import Views.AddDocuments exposing (..)
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Debug exposing (log)
import Json.Encode as JE exposing (object, int)
import Json.Decode exposing (field)
import Updates.Documents exposing (..)
import Updates.Document exposing (updateDocument, createTag, deleteTag, deleteDocument)
import Updates.LocationChange exposing (dispatch)
import String exposing (words)
import Ports.Document exposing (createToken, deleteToken, notifyAddToken, notifyRemoveToken)
import Debug exposing (log)
import Dict


init : Location -> ( AppState, Cmd Msg )
init location =
    let
        currentRoute =
            Routing.parseLocation location

        initialModel =
            Models.initialModel currentRoute

        { phxSocket } =
            initialModel

        ( initPhxSocket, phxCmd ) =
            Phoenix.Socket.join (Phoenix.Channel.init "documents:lobby") phxSocket
    in
        ( { initialModel | phxSocket = initPhxSocket }, Cmd.batch [ Cmd.map PhoenixMsg phxCmd, fetchDocumentTypes, fetchDocuments 0 50 ] )


subscriptions : AppState -> Sub Msg
subscriptions model =
    Sub.batch
        [ Phoenix.Socket.listen model.phxSocket PhoenixMsg
        , createToken CreateToken
        , deleteToken DeleteToken
        ]


view : AppState -> Html Msg
view model =
    case model.route of
        Routing.Home ->
            Layout.layout model (Views.Home.index model)

        Routing.AddDocuments ->
            Layout.layout model (Views.AddDocuments.index model)

        Routing.Document documentId ->
            Layout.layout model (Views.Document.index model documentId)

        Routing.DocumentProperties documentId ->
            Layout.layout model (Views.Document.index model documentId)

        Routing.Documents ->
            Layout.layout model (Views.Documents.index model)

        Routing.Settings ->
            Layout.layout model (Views.Settings.index model)


update : Msg -> AppState -> ( AppState, Cmd Msg )
update msg model =
    case msg of
        OnLocationChange location ->
            dispatch location model

        PhoenixMsg msg ->
            let
                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.update msg model.phxSocket
            in
                ( { model | phxSocket = phxSocket }, Cmd.map PhoenixMsg phxCmd )

        OnDocumentTypes result ->
            ( updateOnDocumentTypes model result, Cmd.none )

        OnDocuments result ->
            let
                currentDocuments =
                    case model.documents of
                        Just x ->
                            x

                        Nothing ->
                            Dict.empty

                newDocuments =
                    case updateDocuments result of
                        Just x ->
                            x

                        Nothing ->
                            Dict.empty

                unionDocuments =
                    Dict.union currentDocuments newDocuments
            in
                ( { model | documents = Just unionDocuments }, Cmd.none )

        OnDocument result ->
            ( updateDocument model result, Cmd.none )

        DidTagCreated result ->
            ( model, Cmd.none )

        DidTagDeleted result ->
            ( model, Cmd.none )

        CreateToken ( document_id, tag ) ->
            ( model, createTag document_id tag )

        DeleteToken ( document_id, tag ) ->
            ( model, deleteTag document_id tag )

        DeleteDocument document_id ->
            ( model, deleteDocument document_id )

        DidDocumentDeleted result ->
            case result of
                Ok x ->
                    let
                        { document_id } =
                            x

                        local_documents =
                            case model.documents of
                                Nothing ->
                                    Nothing

                                Just x ->
                                    Just (Dict.remove document_id x)
                    in
                        ( { model | documents = local_documents }, Navigation.newUrl "#/documents" )

                Err _ ->
                    ( model, Cmd.none )

        DidSearchKeyPressed criteria ->
            let
                newModel =
                    { model | searchQuery = Just criteria }
            in
                case searchDocuments criteria of
                    Ok x ->
                        ( newModel, x )

                    Err _ ->
                        ( { newModel | searchDocumentsResult = Nothing }, Cmd.none )

        DidDocumentSearched result ->
            ( { model | searchDocumentsResult = updateDocuments result }, Cmd.none )


main : Program Never AppState Msg
main =
    Navigation.program OnLocationChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
