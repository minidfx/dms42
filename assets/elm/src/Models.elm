module Models
    exposing
        ( AppState
        , Msg
        , Document
        , DocumentDateTimes
        , DocumentType
        , Msg(..)
        , initialModel
        , Tag
        , DocumentId
        , DidDocumentDeletedResponse
        )

import Routing exposing (Route, DocumentId)
import Rfc2822Datetime exposing (..)
import Formatting exposing (..)
import Phoenix.Socket
import Phoenix.Channel
import Navigation exposing (Location)
import Json.Encode
import Http exposing (Error)
import Dict exposing (Dict)


type alias DocumentDateTimes =
    { inserted_datetime : Datetime
    , updated_datetime : Datetime
    , original_file_datetime : Datetime
    }


type alias Document =
    { comments : String
    , document_id : String
    , document_type_id : String
    , tags : List String
    , original_file_name : String
    , datetimes : DocumentDateTimes
    , ocr : Maybe String
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
    , searchDocumentsResult : Maybe (Dict String Document)
    , searchQuery : Maybe String
    }


type alias DidDocumentDeletedResponse =
    { document_id : String
    }


type alias Tag =
    String


type alias DocumentId =
    String


type Msg
    = OnLocationChange Location
    | PhoenixMsg (Phoenix.Socket.Msg Msg)
    | OnDocumentTypes (Result Http.Error (List DocumentType))
    | OnDocuments (Result Http.Error (List Document))
    | OnDocument (Result Http.Error Document)
    | DidTagCreated (Result Http.Error ())
    | DidTagDeleted (Result Http.Error ())
    | CreateToken ( String, Tag )
    | DeleteToken ( String, Tag )
    | DeleteDocument DocumentId
    | DidDocumentDeleted (Result Http.Error DidDocumentDeletedResponse)
    | DidSearchKeyPressed String
    | DidDocumentSearched (Result Http.Error (List Document))


initialModel : Route -> AppState
initialModel route =
    { route = route
    , documents = Nothing
    , documentTypes = []
    , searchDocumentsResult = Nothing
    , searchQuery = Nothing
    , phxSocket =
        Phoenix.Socket.init "ws://localhost:4000/socket/websocket"
            |> Phoenix.Socket.withDebug
    }
