module Models exposing (..)

import Browser
import Browser.Navigation as Nav
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
    }


type alias Document =
    { id : String
    }


type alias State =
    { key : Nav.Key
    , url : Url.Url
    , documents : Maybe (List Document)
    , uploading : Bool
    }


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | StartUpload
    | UploadCompleted


modelFactory : Nav.Key -> Url.Url -> State
modelFactory key url =
    State key url Nothing False
