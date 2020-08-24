module Middlewares.Main exposing (update)

import Bootstrap.Modal
import Factories
import Models
import Msgs.Main exposing (MiddlewareContext(..))
import ScrollTo
import Views.AddDocuments
import Views.Document
import Views.Documents
import Views.Home
import Views.Settings
import Views.Shared
import Views.Tags


update : Msgs.Main.Msg -> Models.State -> MiddlewareContext
update msg state =
    case msg of
        Msgs.Main.TagsMsg tagsMsg ->
            Continue <| Views.Tags.update state tagsMsg

        Msgs.Main.DocumentsMsg documentsMsg ->
            Continue <| Views.Documents.update state documentsMsg Nothing

        Msgs.Main.HomeMsg homeMsg ->
            Continue <| Views.Home.update state homeMsg Nothing

        Msgs.Main.SettingsMsg settingsMsg ->
            Continue <| Views.Settings.update state settingsMsg

        Msgs.Main.DocumentMsg documentMsg ->
            Continue <| Views.Document.update state documentMsg Nothing

        Msgs.Main.AddDocumentMsg addDocumentMsg ->
            Continue <| Views.AddDocuments.update state addDocumentMsg

        Msgs.Main.GotAndLoadTags result ->
            Continue <| Views.Shared.handleTags state result True

        Msgs.Main.GotTags result ->
            Continue <| Views.Shared.handleTags state result False

        Msgs.Main.GotUserTimeZone zone ->
            Continue <|
                ( { state | userTimeZone = Just zone }
                , Cmd.none
                )

        Msgs.Main.GotViewPort viewport ->
            Continue <| ( { state | viewPort = Just viewport }, Cmd.none )

        Msgs.Main.CloseModal ->
            Continue <| ( { state | modalVisibility = Nothing }, Cmd.none )

        Msgs.Main.ShowModal id ->
            Continue <| ( { state | modalVisibility = Just <| Factories.modalFactory id Bootstrap.Modal.shown }, Cmd.none )

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

        Msgs.Main.Nop ->
            Continue <| ( state, Cmd.none )

        _ ->
            Continue <| ( state, Cmd.none )
