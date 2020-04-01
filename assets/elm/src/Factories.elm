module Factories exposing (..)

import Browser.Navigation as Nav
import Models
import Url


stateFactory : Nav.Key -> Url.Url -> Models.Route -> Models.State
stateFactory key url route =
    Models.State key url route Nothing Nothing False Nothing Nothing False


documentsStateFactory : Models.DocumentsState
documentsStateFactory =
    { documents = Nothing
    , documentsRequest = Nothing
    , total = 0
    , length = 0
    }
