module Msgs.Main exposing (..)

import Bootstrap.Modal
import Bootstrap.Navbar
import Browser
import Browser.Dom
import Http
import Models
import Msgs.AddDocument
import Msgs.Alerts
import Msgs.Document
import Msgs.Documents
import Msgs.Home
import Msgs.Settings
import Msgs.Tags
import ScrollTo
import Time
import Url


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotUserTimeZone Time.Zone
    | GotViewPort Browser.Dom.Viewport
    | CloseModal
    | ShowModal String
    | AnimatedModal Bootstrap.Modal.Visibility
    | ScrollToTop
    | ScrollToMsg ScrollTo.Msg
    | NavbarMsg Bootstrap.Navbar.State
    | GotTags (Result Http.Error (List String))
    | GotAndLoadTags (Result Http.Error (List String))
    | SettingsMsg Msgs.Settings.Msg
    | HomeMsg Msgs.Home.Msg
    | DocumentsMsg Msgs.Documents.Msg
    | DocumentMsg Msgs.Document.Msg
    | AddDocumentMsg Msgs.AddDocument.Msg
    | TagsMsg Msgs.Tags.Msg
    | AlertMsg Msgs.Alerts.Msg
    | Nop


type MiddlewareContext
    = Continue ( Models.State, Cmd Msg )
    | Break ( Models.State, Cmd Msg )
