module Models exposing (AppState, Msg, Document, DocumentType, Msg(..), initialModel)

import Routing exposing (Route)
import Rfc2822Datetime exposing (..)
import Formatting exposing (..)
import Phoenix.Socket
import Phoenix.Channel
import Navigation exposing (Location)
import Json.Encode
import Http exposing (Error)
import Dict exposing (Dict)


type alias Document =
    { thumbnailPath : String
    , insertedAt : Datetime
    , updatedAt : Datetime
    , comments : String
    , document_id : String
    , document_type_id : String
    , tags : List String
    }


type alias DocumentType =
    { name : String
    , id : String
    }


type alias AppState =
    { route : Route
    , documents : Maybe (Dict String Document)
    , documentTypes : List DocumentType
    , phxSocket : Phoenix.Socket.Socket Msg
    }


type Msg
    = OnLocationChange Location
    | PhoenixMsg (Phoenix.Socket.Msg Msg)
    | OnDocumentTypes (Result Http.Error (List DocumentType))
    | OnDocuments (Result Http.Error (List Document))
    | OnDocument Json.Encode.Value


initialModel : Route -> AppState
initialModel route =
    { route = route
    , documents = Nothing
    , documentTypes = []
    , phxSocket =
        Phoenix.Socket.init "ws://localhost:4000/socket/websocket"
            |> Phoenix.Socket.withDebug
    }
