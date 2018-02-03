module Main exposing (..)

import Layout exposing (..)
import Html exposing (Html)
import Http exposing (send)
import Models exposing (AppState, Document, Msg, Msg(..), initialModel)
import Routing exposing (..)
import Navigation exposing (Location)
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
import Updates.Document exposing (updateDocument)
import Updates.LocationChange exposing (dispatch)
import String exposing (words)


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
    Phoenix.Socket.listen model.phxSocket PhoenixMsg


view : AppState -> Html Msg
view model =
    case model.route of
        Routing.Home ->
            Layout.layout model (Views.Home.index model)

        Routing.AddDocuments ->
            Layout.layout model (Views.AddDocuments.index model)

        Routing.Document documentId ->
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
            ( updateDocuments model result, Cmd.none )

        OnDocument json ->
            ( updateDocument model json, Cmd.none )


main : Program Never AppState Msg
main =
    Navigation.program OnLocationChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
