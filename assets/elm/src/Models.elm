module Models exposing (..)

import Bootstrap.Modal
import Bootstrap.Navbar
import Browser
import Browser.Navigation as Nav
import Debounce exposing (Debounce)
import Dict exposing (Dict)
import Http
import Ports.Models
import ScrollTo
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


type Route
    = Documents (Maybe Int)
    | Document String (Maybe Int)
    | AddDocuments
    | Settings
    | Home (Maybe String)


type alias State =
    { key : Nav.Key
    , url : Url.Url
    , route : Route
    , documentsState : Maybe DocumentsState
    , tagsResponse : Maybe (List String)
    , isUploading : Bool
    , error : Maybe String
    , userTimeZone : Maybe Time.Zone
    , isLoading : Bool
    , modalVisibility : Bootstrap.Modal.Visibility
    , searchState : Maybe SearchState
    , scrollTo : ScrollTo.State
    , queueInfo : Maybe QueueInfoResponse
    , navBarState : Bootstrap.Navbar.State
    }


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | StartUpload
    | UploadCompleted
    | GotDocuments (Result Http.Error DocumentsResponse)
    | GotDocument (Result Http.Error DocumentResponse)
    | GetUserTimeZone Time.Zone
    | AddTags Ports.Models.TagsAdded
    | RemoveTags Ports.Models.TagsRemoved
    | DidRemoveTags (Result Http.Error ())
    | DidAddTags (Result Http.Error ())
    | CloseModal
    | ShowModal
    | AnimatedModal Bootstrap.Modal.Visibility
    | DeleteDocument String
    | DidDeleteDocument (Result Http.Error ())
    | UserTypeSearch String
    | ThrottleSearchDocuments Debounce.Msg
    | GotSearchResult (Result Http.Error (List DocumentResponse))
    | RunOcr DocumentResponse
    | RunUpdateThumbnails DocumentResponse
    | RunUpdateAll DocumentResponse
    | DidRunOcr (Result Http.Error ())
    | DidRunUpdateThumbnails (Result Http.Error ())
    | GotQueueInfo (Result Http.Error QueueInfoResponse)
    | ScrollToTop
    | ScrollToMsg ScrollTo.Msg
    | NavbarMsg Bootstrap.Navbar.State
    | Nop
