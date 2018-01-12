module Main exposing (..)

import Layout exposing (..)
import Html exposing (..)
import Models.Application exposing (..)
import Routing exposing (..)
import Navigation exposing (Location)
import Models.Msgs exposing (..)
import Views.Home exposing (..)
import Views.Documents exposing (..)
import Views.Document exposing (..)
import Views.Settings exposing (..)


init : Location -> ( Models.Application.AppModel, Cmd Models.Msgs.Msg )
init location =
    let
        currentRoute =
            Routing.parseLocation location
    in
        ( Models.Application.initialModel currentRoute, Cmd.none )


subscriptions : Models.Application.AppModel -> Sub Models.Msgs.Msg
subscriptions model =
    Sub.none


view : Models.Application.AppModel -> Html msg
view model =
    case model.route of
        Routing.Home ->
            Layout.layout model (Views.Home.index model)

        Routing.Document documentId ->
            Layout.layout model (Views.Document.index model documentId)

        Routing.Documents ->
            Layout.layout model (Views.Documents.index model)

        Routing.Settings ->
            Layout.layout model (Views.Settings.index model)


update : Models.Msgs.Msg -> Models.Application.AppModel -> ( Models.Application.AppModel, Cmd Models.Msgs.Msg )
update msg model =
    case msg of
        Models.Msgs.OnLocationChange location ->
            let
                newRoute =
                    Routing.parseLocation location
            in
                ( { model | route = newRoute }, Cmd.none )


main : Program Never Models.Application.AppModel Models.Msgs.Msg
main =
    Navigation.program Models.Msgs.OnLocationChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
