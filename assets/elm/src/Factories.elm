module Factories exposing (..)

import Bootstrap.Modal
import Browser.Navigation as Nav
import Debounce
import Models
import Url


stateFactory : Nav.Key -> Url.Url -> Models.Route -> Models.State
stateFactory key url route =
    { key = key
    , url = url
    , route = route
    , documentsState = Nothing
    , tagsResponse = Nothing
    , isUploading = False
    , error = Nothing
    , userTimeZone = Nothing
    , isLoading = False
    , modalVisibility = Bootstrap.Modal.hidden
    , searchState = Nothing
    }


searchStateFactory : Models.SearchState
searchStateFactory =
    Models.SearchState Nothing Nothing Debounce.init


documentsStateFactory : Models.DocumentsState
documentsStateFactory =
    { documents = Nothing
    , total = 0
    , length = 40
    }
