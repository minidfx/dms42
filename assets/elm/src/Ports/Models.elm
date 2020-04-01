module Ports.Models exposing (..)


type alias TagsRequest =
    { jQueryPath : String
    , registerEvents : Bool
    , documentId : Maybe String
    }


type alias DropZoneRequest =
    { jQueryPath : String
    , jQueryTagsPath : String
    }


type alias UploadRequest =
    { jQueryPath : String
    , jQueryTagsPath : String
    }


type alias TagsRemoved =
    { tags : List String
    , documentId : String
    }


type alias TagsAdded =
    { tags : List String
    , documentId : String
    }
