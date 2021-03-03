module Middlewares.Updates exposing (..)

import Models
import Msgs.Main exposing (MiddlewareContext(..))
import Views.AddDocuments
import Views.Document
import Views.Documents
import Views.Home
import Views.Settings
import Views.Shared
import Views.Tags


update : Msgs.Main.Msg -> Models.State -> MiddlewareContext
update msg ({ history } as state) =
    case msg of
        Msgs.Main.GotAndLoadTags result ->
            Continue <| Views.Shared.handleTags state result True

        Msgs.Main.GotTags result ->
            Continue <| Views.Shared.handleTags state result False

        Msgs.Main.TagsMsg tagsMsg ->
            Continue <| Views.Tags.update state tagsMsg

        Msgs.Main.HomeMsg homeMsg ->
            Continue <| Views.Home.update state homeMsg Nothing

        Msgs.Main.SettingsMsg settingsMsg ->
            Continue <| Views.Settings.update state settingsMsg

        Msgs.Main.AddDocumentMsg addDocumentMsg ->
            Continue <| Views.AddDocuments.update state addDocumentMsg

        Msgs.Main.DocumentsMsg documentsMsg ->
            Continue <| Views.Documents.update state documentsMsg Nothing

        Msgs.Main.DocumentMsg documentMsg ->
            Continue <| Views.Document.update state documentMsg Nothing Nothing

        _ ->
            Continue ( state, Cmd.none )
