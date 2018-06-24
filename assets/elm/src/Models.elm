module Models exposing (..)

import Routing
import Navigation
import Json.Encode
import Http
import Dict exposing (Dict)
import Rfc2822Datetime
import Phoenix.Socket
import Websocket
import Json.Encode
import Debouncer.Messages as Debouncer exposing (Debouncer)
import Time


type alias DocumentDateTimes =
    { inserted_datetime : Rfc2822Datetime.Datetime
    , updated_datetime : Maybe Rfc2822Datetime.Datetime
    , original_file_datetime : Rfc2822Datetime.Datetime
    }


type alias Document =
    { comments : Maybe String
    , document_id : String
    , document_type_id : String
    , tags : List String
    , original_file_name : String
    , datetimes : DocumentDateTimes
    , count_images : Int
    , ocr : Maybe String
    }


type alias DocumentType =
    { name : String
    , id : String
    }


type alias AppState =
    { route : Routing.Route
    , documents : Maybe (Dict String Document)
    , documentTypes : Maybe (List DocumentType)
    , searchDocumentsResult : Maybe (Dict String Document)
    , searchQuery : Maybe String
    , phxSocket : Phoenix.Socket.Socket Msg
    , debouncer : Debouncer Msg
    }


type alias Tag =
    String


type alias DocumentId =
    String


type alias InitialLoad =
    { documentTypes : List DocumentType
    , documents : List Document
    }


type Msg
    = OnLocationChange Navigation.Location
    | JoinChannel
    | PhoenixMsg (Phoenix.Socket.Msg Msg)
    | ReceiveInitialLoad Json.Encode.Value
    | ReceiveNewDocument Json.Encode.Value
    | UpdateDocumentComments String DocumentId
    | ReceiveUpdateDocument Json.Encode.Value
    | DebounceOneSecond (Debouncer.Msg Msg)


initPhxSocket : Phoenix.Socket.Socket Msg
initPhxSocket =
    Phoenix.Socket.init Websocket.socketServer
        |> Phoenix.Socket.withDebug
        |> Phoenix.Socket.on "initialLoad" "documents:lobby" ReceiveInitialLoad
        |> Phoenix.Socket.on "newDocument" "documents:lobby" ReceiveNewDocument
        |> Phoenix.Socket.on "updateDocument" "documents:lobby" ReceiveUpdateDocument


initialModel : Routing.Route -> AppState
initialModel route =
    { route = route
    , documents = Nothing
    , documentTypes = Nothing
    , searchDocumentsResult = Nothing
    , searchQuery = Nothing
    , phxSocket = initPhxSocket
    , debouncer =
        Debouncer.config
            |> Debouncer.settleWhenQuietFor (1 * Time.second)
            |> Debouncer.toDebouncer
    }
