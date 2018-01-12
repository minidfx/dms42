module Main exposing (..)

import Layout exposing (..)
import Html exposing (..)
import Models.Application exposing (..)
import Views.Home exposing (..)
import Routing exposing (..)
import Navigation exposing (Location)
import Models.Msgs exposing (..)


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


update : Models.Msgs.Msg -> Models.Application.AppModel -> ( Models.Application.AppModel, Cmd Models.Msgs.Msg )
update msg model =
    case msg of
        Msgs.OnLocationChange location ->
            let
                newRoute =
                    Routing.parseLocation location
            in
                ( { model | route = newRoute }, Cmd.none )


view : Models.Application.AppModel -> Html msg
view model =
    Layout.layout Views.Home.index


main : Program Never Models.Application.AppModel Models.Msgs.Msg
main =
    Navigation.program Models.Msgs.OnLocationChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
