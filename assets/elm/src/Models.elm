module Models exposing (..)

import Browser
import Browser.Navigation as Nav
import Http
import Time
import Url


type alias TagsRequest =
    { jQueryPath : String
    , existingTags : List String
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


type alias Document =
    { comments : Maybe String
    , id : String
    , type_id : String
    , tags : List String
    , original_file_name : String
    , datetimes : DocumentDateTimes
    , thumbnails : DocumentThumbnails
    , ocr : Maybe String
    }


type alias Documents =
    { documents : List Document
    , total : Int
    }


type alias DocumentsRequest =
    { offset : Int
    , length : Int
    }


type alias State =
    { key : Nav.Key
    , url : Url.Url
    , documents : Maybe Documents
    , documentsRequest : Maybe DocumentsRequest
    , uploading : Bool
    }


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | StartUpload
    | UploadCompleted
    | GotDocuments (Result Http.Error Documents)
    | Error String


modelFactory : Nav.Key -> Url.Url -> State
modelFactory key url =
    State key url Nothing Nothing False
