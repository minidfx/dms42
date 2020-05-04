module Msgs.Main exposing (..)

import Bootstrap.Modal
import Bootstrap.Navbar
import Browser
import Http
import Msgs.AddDocument
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
    | GetUserTimeZone Time.Zone
    | CloseModal
    | ShowModal
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
    | Nop
