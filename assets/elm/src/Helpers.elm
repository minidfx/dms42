module Helpers exposing (..)

import Html exposing (Html)
import Html.Attributes
import Models
import Task
import Dict exposing (Dict)
import Rfc2822Datetime
import Control
import Control.Debounce as Debounce
import Time exposing (Time)


script : String -> Html Models.Msg
script code =
    Html.node "script" [ Html.Attributes.type_ "text/javascript" ] [ Html.text code ]


sendMsg : Models.Msg -> Cmd Models.Msg
sendMsg msg =
    Task.succeed msg |> Task.perform identity


mergeDocument : Maybe (Dict String Models.Document) -> Models.Document -> Dict String Models.Document
mergeDocument documents newDocument =
    mergeDocuments [ newDocument ] documents


mergeDocuments :
    List Models.Document
    -> Maybe (Dict String Models.Document)
    -> Dict String Models.Document
mergeDocuments newDocuments documents =
    case documents of
        Nothing ->
            newDocuments |> documentsToDict

        Just x ->
            Dict.union (newDocuments |> documentsToDict) x


updateDocument :
    Models.Document
    -> Models.AppState
    -> Result String Models.AppState
updateDocument document state =
    let
        { document_id, comments, document_type_id, tags, original_file_name, datetimes, thumbnails, ocr } =
            document

        localUpdateDocumentFunc =
            (\x ->
                { x
                    | comments = comments
                    , document_type_id = document_type_id
                    , tags = tags
                    , original_file_name = original_file_name
                    , datetimes = datetimes
                    , thumbnails = thumbnails
                    , ocr = ocr
                }
            )
    in
        updateDocumentProperties document_id localUpdateDocumentFunc state


updateDocumentProperties :
    String
    -> (Models.Document -> Models.Document)
    -> Models.AppState
    -> Result String Models.AppState
updateDocumentProperties document_id updateFunction state =
    let
        documents =
            Maybe.withDefault Dict.empty state.documents

        document =
            Dict.get document_id documents
    in
        case document of
            Nothing ->
                Err ("The given document_id is not found: " ++ document_id)

            Just x ->
                let
                    newDocument =
                        updateFunction x

                    newDocuments =
                        Dict.insert document_id newDocument documents

                    newState =
                        { state | documents = Just newDocuments }
                in
                    Ok newState


removeDocument :
    Maybe (Dict String Models.Document)
    -> Models.DocumentId
    -> Dict String Models.Document
removeDocument documents document_id =
    case documents of
        Nothing ->
            Dict.empty

        Just x ->
            Dict.remove document_id x


removeDocument2 :
    Maybe (List Models.Document)
    -> Models.DocumentId
    -> List Models.Document
removeDocument2 documents document_id =
    let
        local_document_id =
            document_id
    in
        case documents of
            Nothing ->
                []

            Just x ->
                List.filter (\{ document_id } -> document_id == local_document_id) x


documentsToDict : List Models.Document -> Dict String Models.Document
documentsToDict documents =
    documents
        |> List.map (\x -> ( x.document_id, x ))
        |> Dict.fromList


getDocument : Models.AppState -> String -> Maybe Models.Document
getDocument { documents } documentId =
    case documents of
        Nothing ->
            Nothing

        Just x ->
            Dict.get documentId x


defaultDateTime : Rfc2822Datetime.Datetime
defaultDateTime =
    { dayOfWeek = Nothing
    , date = { year = 1970, month = Rfc2822Datetime.Jan, day = 1 }
    , time = { hour = 0, minute = 0, second = Nothing, zone = Rfc2822Datetime.UT }
    }


dateTimeToString : Rfc2822Datetime.Datetime -> String
dateTimeToString { date, time } =
    let
        { day, month, year } =
            date

        { hour, minute } =
            time
    in
        (toString day) ++ " " ++ (toString month) ++ " " ++ (toString year) ++ " " ++ (toString hour) ++ ":" ++ (toString minute)


getDocumentType : Models.AppState -> String -> Models.DocumentType
getDocumentType state document_type_id =
    let
        default =
            { name = "Unknown document type", id = "no-id" }
    in
        case state.documentTypes of
            Nothing ->
                default

            Just x ->
                Maybe.withDefault default (x |> List.filter (\x -> x.id == document_type_id) |> List.head)


debounce : Models.Msg -> Models.Msg
debounce =
    Debounce.trailing Models.Debouncer (Time.inMilliseconds 500)
