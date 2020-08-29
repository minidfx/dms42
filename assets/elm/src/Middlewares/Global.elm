module Middlewares.Global exposing (update)

import Bootstrap.Modal
import Factories
import Models
import Msgs.Main exposing (MiddlewareContext(..))
import ScrollTo


update : Msgs.Main.Msg -> Models.State -> MiddlewareContext
update msg state =
    case msg of
        Msgs.Main.GotUserTimeZone zone ->
            Continue <|
                ( { state | userTimeZone = Just zone }
                , Cmd.none
                )

        Msgs.Main.GotViewPort viewport ->
            Continue <| ( { state | viewPort = Just viewport }, Cmd.none )

        Msgs.Main.AnimatedModal visibility ->
            case state.modalVisibility of
                Just modal ->
                    Continue <| ( { state | modalVisibility = Just <| { modal | visibility = visibility } }, Cmd.none )

                Nothing ->
                    Continue <| ( state, Cmd.none )

        Msgs.Main.ScrollToTop ->
            Continue <|
                ( state
                , Cmd.map Msgs.Main.ScrollToMsg <| ScrollTo.scrollToTop
                )

        Msgs.Main.ScrollToMsg scrollToMsg ->
            let
                ( scrollToModel, scrollToCmds ) =
                    ScrollTo.update
                        scrollToMsg
                        state.scrollTo
            in
            Continue <|
                ( { state | scrollTo = scrollToModel }
                , Cmd.map Msgs.Main.ScrollToMsg scrollToCmds
                )

        Msgs.Main.NavbarMsg navBarState ->
            Continue <| ( { state | navBarState = navBarState }, Cmd.none )

        Msgs.Main.CloseModal ->
            Continue <| ( { state | modalVisibility = Nothing }, Cmd.none )

        Msgs.Main.ShowModal id ->
            Continue <| ( { state | modalVisibility = Just <| Factories.modalFactory id Bootstrap.Modal.shown }, Cmd.none )

        _ ->
            Continue <| ( state, Cmd.none )
