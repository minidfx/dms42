module Models exposing (..)

import Browser
import Browser.Navigation as Nav
import Dict exposing (Dict)
import Http
import Json.Encode
import Ports.Models
import Time exposing (Posix)
import Url


type alias DocumentThumbnails =
    { countImages : Int
    , currentImage : Maybe Int
    }


type alias DocumentDateTimes =
    { inserted_datetime : Time.Posix
    , updated_datetime : Maybe Time.Posix
    , original_file_datetime : Time.Posix
    }


type alias DocumentResponse =
    { comments : Maybe String
    , id : String
    , type_id : String
    , tags : List String
    , original_file_name : String
    , datetimes : DocumentDateTimes
    , thumbnails : DocumentThumbnails
    , ocr : Maybe String
    }


type alias DocumentsResponse =
    { documents : List DocumentResponse
    , total : Int
    }


type alias DocumentsRequest =
    { offset : Int
    , length : Int
    }


type alias DocumentsState =
    { documents : Maybe (Dict String DocumentResponse)
    , documentsRequest : Maybe DocumentsRequest
    , length : Int
    , total : Int
    }


type Route
    = Documents (Maybe Int)
    | Document String
    | AddDocuments
    | Settings
    | Home


type alias State =
    { key : Nav.Key
    , url : Url.Url
    , route : Route
    , documentsState : Maybe DocumentsState
    , tagsResponse : Maybe (List String)
    , uploading : Bool
    , error : Maybe String
    , userTimeZone : Maybe Time.Zone
    , isLoading : Bool
    }


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | StartUpload
    | UploadCompleted
    | GotDocuments (Result Http.Error DocumentsResponse)
    | PaginationMsg Int
    | GetUserTimeZone Time.Zone
    | AddTags Ports.Models.TagsAdded
    | RemoveTags Ports.Models.TagsRemoved
    | DidRemoveTags (Result Http.Error ())
    | DidAddTags (Result Http.Error ())
    | None
