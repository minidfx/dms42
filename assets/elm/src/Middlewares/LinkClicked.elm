module Middlewares.LinkClicked exposing (..)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Models
import Msgs.Main exposing (MiddlewareContext(..))
import Url


update : Msgs.Main.Msg -> Models.State -> MiddlewareContext
update msg state =
    case msg of
        Msgs.Main.LinkClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    Break ( state, Nav.pushUrl state.key (Url.toString url) )

                External href ->
                    Break ( state, Nav.load href )

        _ ->
            Continue ( state, Cmd.none )
