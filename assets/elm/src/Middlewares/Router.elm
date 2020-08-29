module Middlewares.Router exposing (..)

import Models
import Msgs.AddDocument
import Msgs.Document
import Msgs.Documents
import Msgs.Home
import Msgs.Main exposing (MiddlewareContext(..))
import Msgs.Settings
import Msgs.Tags
import Url.Parser exposing ((</>), (<?>))
import Url.Parser.Query
import Views.AddDocuments
import Views.Document
import Views.Documents
import Views.Home
import Views.Settings
import Views.Tags


routes : Url.Parser.Parser (Models.Route -> a) a
routes =
    Url.Parser.oneOf
        [ Url.Parser.map Models.Documents (Url.Parser.s "documents" <?> Url.Parser.Query.int "offset")
        , Url.Parser.map Models.AddDocuments (Url.Parser.s "documents" </> Url.Parser.s "add")
        , Url.Parser.map Models.Document (Url.Parser.s "documents" </> Url.Parser.string <?> Url.Parser.Query.int "offset")
        , Url.Parser.map Models.Settings (Url.Parser.s "settings")
        , Url.Parser.map Models.Tags (Url.Parser.s "tags")
        , Url.Parser.map Models.Home (Url.Parser.top <?> Url.Parser.Query.string "query")
        ]


update : Msgs.Main.Msg -> Models.State -> MiddlewareContext
update msg ({ tagsLoaded, history } as state) =
    case msg of
        Msgs.Main.UrlChanged url ->
            let
                route =
                    Url.Parser.parse routes url |> Maybe.withDefault (Models.Home Nothing)

                newState =
                    { state | url = url, route = route, error = Nothing }
            in
            case route of
                Models.AddDocuments ->
                    Continue <| Views.AddDocuments.update newState Msgs.AddDocument.Home

                Models.Documents offset ->
                    Continue <| Views.Documents.update newState Msgs.Documents.Home offset

                Models.Document documentId _ ->
                    Continue <| Views.Document.update newState Msgs.Document.Home (Just documentId)

                Models.Settings ->
                    Continue <| Views.Settings.update newState Msgs.Settings.Home

                Models.Home query ->
                    Continue <| Views.Home.update newState Msgs.Home.Home query

                Models.Tags ->
                    Continue <| Views.Tags.update newState Msgs.Tags.Home

        _ ->
            Continue ( state, Cmd.none )
