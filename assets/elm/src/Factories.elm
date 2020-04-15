module Factories exposing (..)

import Bootstrap.Modal
import Bootstrap.Navbar
import Browser.Navigation as Nav
import Debounce
import Models
import ScrollTo
import Url


stateFactory : Nav.Key -> Url.Url -> Models.Route -> Bootstrap.Navbar.State -> Models.State
stateFactory key url route navBarState =
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
    , scrollTo = ScrollTo.init
    , queueInfo = Nothing
    , navBarState = navBarState
    }


queueInfoFactory : Models.QueueInfoResponse
queueInfoFactory =
    Models.QueueInfoResponse 0 0 0


searchStateFactory : Models.SearchState
searchStateFactory =
    Models.SearchState Nothing Nothing Debounce.init


documentsStateFactory : Models.DocumentsState
documentsStateFactory =
    { documents = Nothing
    , total = 0
    , length = 40
    }
