module Models exposing (..)

import Browser
import Browser.Navigation as Nav
import Dict exposing (Dict)
import Http
import Time
import Url


type alias TagsRequest =
    { jQueryPath : String
    }


type alias DropZoneRequest =
    { jQueryPath : String
    , jQueryTagsPath : String
    }


type alias UploadRequest =
    { jQueryPath : String
    , jQueryTagsPath : String
    }


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
    , offset : Int
    , length : Int
    , total : Int
    , document : Maybe DocumentResponse
    }


type Route
    = Documents
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
    }


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | StartUpload
    | UploadCompleted
    | GotDocuments (Result Http.Error DocumentsResponse)
    | PaginationMsg Int
