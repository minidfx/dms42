module Main exposing (..)

import Layout exposing (..)
import Html exposing (..)
import Models.Application exposing (..)
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
import Json.Decode exposing (field)
import Updates.Documents exposing (..)


init : Location -> ( Models.Application.AppModel, Cmd Models.Application.Msg )
init location =
    let
        currentRoute =
            Routing.parseLocation location

        initialModel =
            Models.Application.initialModel currentRoute

        { phxSocket } =
            initialModel

        ( newPhxSocket, phxCmd ) =
            Phoenix.Socket.join (Phoenix.Channel.init "documents:lobby") phxSocket
    in
        ( { initialModel | phxSocket = newPhxSocket }, Cmd.map PhoenixMsg phxCmd )


subscriptions : Models.Application.AppModel -> Sub Models.Application.Msg
subscriptions model =
    Phoenix.Socket.listen model.phxSocket PhoenixMsg


view : Models.Application.AppModel -> Html Msg
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


update : Models.Application.Msg -> Models.Application.AppModel -> ( Models.Application.AppModel, Cmd Models.Application.Msg )
update msg model =
    case msg of
        Models.Application.OnLocationChange location ->
            ( { model | route = Routing.parseLocation location }, Cmd.none )

        Models.Application.PhoenixMsg msg ->
            let
                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.update msg model.phxSocket
            in
                ( { model | phxSocket = phxSocket }, Cmd.map PhoenixMsg phxCmd )

        Models.Application.DocumentTypes json ->
            ( updateDocumentTypes model (log "document-types" json), Cmd.none )


main : Program Never Models.Application.AppModel Models.Application.Msg
main =
    Navigation.program Models.Application.OnLocationChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
