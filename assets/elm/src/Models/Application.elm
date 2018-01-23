module Models.Application exposing (..)

import Routing exposing (Route)
import Rfc2822Datetime exposing (..)
import Formatting exposing (..)
import Phoenix.Socket
import Phoenix.Channel
import Navigation exposing (Location)
import Json.Encode


type alias Document =
    { name : String
    , thumbnailPath : String
    , creationDateTime : Datetime
    , lastUpdateDateTime : Datetime
    , comments : String
    }


type alias DocumentType =
    { name : String
    , id : String
    }


type alias UploadDocument =
    { fileName : String }


type alias AppModel =
    { route : Route
    , documents : List Document
    , documentTypes : List DocumentType
    , phxSocket : Phoenix.Socket.Socket Msg
    }


type Msg
    = OnLocationChange Location
    | PhoenixMsg (Phoenix.Socket.Msg Msg)
    | DocumentTypes Json.Encode.Value


createFakeDocument : Int -> Document
createFakeDocument index =
    { name = print (s "Document " <> int) index
    , thumbnailPath = ""
    , creationDateTime =
        { dayOfWeek = Just Mon
        , date =
            { year = 2017
            , month = Jan
            , day = 1
            }
        , time =
            { hour = 0
            , minute = 0
            , second = Just 1
            , zone = Offset 0
            }
        }
    , lastUpdateDateTime =
        { dayOfWeek = Just Mon
        , date =
            { year = 2017
            , month = Jan
            , day = 1
            }
        , time =
            { hour = 0
            , minute = 0
            , second = Just 1
            , zone = Offset 0
            }
        }
    , comments = "Officia aute sint esse ipsum consectetur incididunt ex enim occaecat magna fugiat."
    }


initialModel : Route -> AppModel
initialModel route =
    { route = route
    , documents =
        [ createFakeDocument 1
        , createFakeDocument 2
        , createFakeDocument 3
        , createFakeDocument 4
        , createFakeDocument 5
        , createFakeDocument 6
        ]
    , documentTypes = []
    , phxSocket =
        Phoenix.Socket.init "ws://localhost:4000/socket/websocket"
            |> Phoenix.Socket.withDebug
            |> Phoenix.Socket.on "documentTypes" "documents:lobby" DocumentTypes
    }
