module Ports.Models exposing (..)


type alias TagsRequest =
    { jQueryPath : String
    , documentId : Maybe String
    , tags : List String
    , documentTags : List String
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
