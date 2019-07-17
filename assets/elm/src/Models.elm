module Models exposing (AppState, Document, DocumentComments, DocumentDateTimes, DocumentId, DocumentOcr, DocumentTags, DocumentThumbnails, DocumentType, Documents, ModalId, Msg(..), Page, Query, SearchResult, Tag, initPhxSocket, initialModel)

import Bootstrap.Modal
import Control exposing (Control)
import Dict exposing (Dict)
import Http
import Json.Encode
import Navigation
import Phoenix.Socket
import Rfc2822Datetime
import Routing
import Time exposing (Time)


type alias DocumentDateTimes =
    { inserted_datetime : Rfc2822Datetime.Datetime
    , updated_datetime : Maybe Rfc2822Datetime.Datetime
    , original_file_datetime : Rfc2822Datetime.Datetime
    }


type alias DocumentOcr =
    { document_id : String
    , ocr : String
    }


type alias DocumentComments =
    { document_id : String
    , comments : Maybe String
    , updated_datetime : Rfc2822Datetime.Datetime
    }


type alias DocumentThumbnails =
    { countImages : Int
    , currentImage : Maybe Int
    }


type alias Document =
    { comments : Maybe String
    , document_id : String
    , document_type_id : String
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


type alias SearchResult =
    { documents : List Document
    }


type alias DocumentType =
    { name : String
    , id : String
    }


type alias AppState =
    { route : Routing.Route
    , documents : Maybe (Dict String Document)
    , documentTypes : Maybe (List DocumentType)
    , searchQuery : Maybe String
    , searchResult : Maybe (List Document)
    , phxSocket : Phoenix.Socket.Socket Msg
    , debouncer : Control.State Msg
    , error : Maybe String
    , modalStates : Dict ModalId Bootstrap.Modal.Visibility
    , documentsOffset : Int
    , documentsLength : Int
    , documentsCount : Int
    }


type alias DocumentTags =
    { document_id : String
    , tags : List String
    }


type alias Tag =
    String


type alias DocumentId =
    String


type alias Page =
    Int


type alias Query =
    String


type alias ModalId =
    String


type Msg
    = OnLocationChange Navigation.Location
    | JoinChannel
    | PhoenixMsg (Phoenix.Socket.Msg Msg)
    | ReceiveNewDocument Json.Encode.Value
    | ReceiveNewDocuments (Result Http.Error Documents)
    | ReceiveNewTags Json.Encode.Value
    | ReceiveDocumentTypes (Result Http.Error (List DocumentType))
    | UpdateDocumentComments DocumentId String
    | ChangeDocumentPage DocumentId Page
    | Search Query
    | ReceiveSearchResult Json.Encode.Value
    | Debouncer (Control Msg)
    | CloseModal ModalId
    | ShowModal ModalId
    | DeleteDocument DocumentId
    | DocumentDeleted (Result Http.Error String)
    | FetchDocument DocumentId
    | FetchDocuments Int Int
    | FetchDocumentTypes
    | ChangeDocumentsPage Page
    | ReceiveOcr Json.Encode.Value
    | ReceiveComments Json.Encode.Value
    | ProcessOcr DocumentId
    | NewTag ( Tag, DocumentId )
    | DeleteTag ( Tag, DocumentId )
    | ProcessAllThumbnails


initPhxSocket : Navigation.Location -> Phoenix.Socket.Socket Msg
initPhxSocket { hostname } =
    Phoenix.Socket.init ("ws://" ++ hostname ++ ":4000/socket/websocket")
        |> Phoenix.Socket.withHeartbeatInterval 30
        |> Phoenix.Socket.withDebug
        |> Phoenix.Socket.on "newDocument" "documents:lobby" ReceiveNewDocument
        |> Phoenix.Socket.on "newTags" "documents:lobby" ReceiveNewTags
        |> Phoenix.Socket.on "comments" "documents:lobby" ReceiveComments
        |> Phoenix.Socket.on "searchResult" "documents:lobby" ReceiveSearchResult
        |> Phoenix.Socket.on "ocr" "documents:lobby" ReceiveOcr


initialModel : Navigation.Location -> Routing.Route -> AppState
initialModel location route =
    { route = route
    , documents = Nothing
    , documentTypes = Nothing
    , searchQuery = Nothing
    , searchResult = Nothing
    , phxSocket = initPhxSocket location
    , debouncer = Control.initialState
    , error = Nothing
    , modalStates = Dict.empty
    , documentsOffset = 0
    , documentsLength = 20
    , documentsCount = 0
    }
