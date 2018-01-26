module Models.Application exposing (..)

import Routing exposing (Route)
import Rfc2822Datetime exposing (..)
import Formatting exposing (..)
import Phoenix.Socket
import Phoenix.Channel
import Navigation exposing (Location)
import Json.Encode


type alias Document =
    { thumbnailPath : String
    , insertedAt : Datetime
    , updatedAt : Datetime
    , comments : String
    , document_id : String
    , document_type_id : String
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
    | Documents Json.Encode.Value


initialModel : Route -> AppModel
initialModel route =
    { route = route
    , documents =
        []
    , documentTypes = []
    , phxSocket =
        Phoenix.Socket.init "ws://localhost:4000/socket/websocket"
            |> Phoenix.Socket.withDebug
            |> Phoenix.Socket.on "documentTypes" "documents:lobby" DocumentTypes
            |> Phoenix.Socket.on "documents" "documents:lobby" Documents
    }
