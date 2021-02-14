module Models exposing (..)

import Bootstrap.Modal
import Bootstrap.Navbar
import Browser.Dom
import Browser.Navigation as Nav
import Debounce exposing (Debounce)
import Dict exposing (Dict)
import ScrollTo
import Set exposing (Set)
import Time exposing (Posix)
import Url


type alias DocumentThumbnails =
    { countImages : Int
    , offset : Maybe Int
    }


type alias DocumentDateTimes =
    { inserted_datetime : Time.Posix
    , updated_datetime : Maybe Time.Posix
    , original_file_datetime : Time.Posix
    }


type alias DocumentResponse =
    { comments : Maybe String
    , id : String
    , tags : List String
    , original_file_name : String
    , datetimes : DocumentDateTimes
    , thumbnails : DocumentThumbnails
    , ocr : Maybe String
    , ranking : Maybe Int
    }


type alias DocumentsResponse =
    { documents : List DocumentResponse
    , total : Int
    }


type alias DocumentsRequest =
    { offset : Int
    , length : Int
    }


type alias DocumentRequest =
    { documentId : String
    , offset : Int
    }


type alias DocumentsState =
    { documents : Maybe (Dict String DocumentResponse)
    , length : Int
    , total : Int
    , offset : Maybe Int
    }


type alias SearchState =
    { documents : Maybe (List DocumentResponse)
    , query : Maybe String
    , debouncer : Debounce String
    }


type alias QueueInfoResponse =
    { processing : Int
    , pending : Int
    , cpus : Int
    }


type alias TagsState =
    { selected : Set String
    , documents : Maybe (List DocumentResponse)
    , filter : Maybe String
    }


type alias Modal =
    { id : String
    , visibility : Bootstrap.Modal.Visibility
    }


type Route
    = Documents (Maybe Int)
    | Document String (Maybe Int)
    | AddDocuments
    | Settings
    | Tags
    | Home (Maybe String)


type alias State =
    { key : Nav.Key
    , url : Url.Url
    , history : List Url.Url
    , route : Route
    , documentsState : Maybe DocumentsState
    , tagsResponse : Maybe (List String)
    , tagsState : Maybe TagsState
    , isUploading : Bool
    , error : Maybe String
    , userTimeZone : Maybe Time.Zone
    , isLoading : Bool
    , modalVisibility : Maybe Modal
    , searchState : Maybe SearchState
    , scrollTo : ScrollTo.State
    , queueInfo : Maybe QueueInfoResponse
    , navBarState : Bootstrap.Navbar.State
    , viewPort : Maybe Browser.Dom.Viewport
    , tagsLoaded : Bool
    }
