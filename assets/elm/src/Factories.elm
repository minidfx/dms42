module Factories exposing (..)

import Bootstrap.Modal
import Bootstrap.Navbar
import Browser.Navigation as Nav
import Debounce
import Models exposing (AlertKind(..), UpdateTagRequest)
import ScrollTo
import Set
import Url


stateFactory : Nav.Key -> Url.Url -> Models.Route -> Bootstrap.Navbar.State -> Models.State
stateFactory key url route navBarState =
    { key = key
    , url = url
    , history = []
    , route = route
    , documentsState = Nothing
    , tagsResponse = Nothing
    , isUploading = False
    , alerts = []
    , userTimeZone = Nothing
    , isLoading = False
    , modalVisibility = Nothing
    , carouselState = Nothing
    , searchState = Nothing
    , scrollTo = ScrollTo.init
    , queueInfo = Nothing
    , navBarState = navBarState
    , tagsState = Nothing
    , viewPort = Nothing
    , tagsLoaded = False
    }


modalFactory : String -> Bootstrap.Modal.Visibility -> Models.Modal
modalFactory id visibility =
    Models.Modal id visibility


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
    , length = 20
    , offset = Nothing
    }


updateTagRequestFactory : String -> UpdateTagRequest
updateTagRequestFactory tag =
    { oldTag = tag, newTag = tag }


tagsStateFactory : Models.TagsState
tagsStateFactory =
    { selected = Set.empty
    , documents = Nothing
    , filter = Nothing
    , updateTagRequest = Nothing
    }
