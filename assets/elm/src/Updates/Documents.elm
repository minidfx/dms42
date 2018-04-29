module Updates.Documents
    exposing
        ( updateOnDocumentTypes
        , updateDocuments
        , fetchDocuments
        , fetchDocumentTypes
        , searchDocuments
        )

import Rfc2822Datetime exposing (..)
import Http
import Models
    exposing
        ( AppState
        , DocumentType
        , Document
        , DocumentDateTimes
        , Msg
        , Msg
            ( OnDocuments
            , OnDocumentTypes
            , DidTagCreated
            , DidTagCreated
            , DidDocumentSearched
            )
        )
import Updates.Document
    exposing
        ( documentDecoder
        , documentDateTimesDecoder
        , datetime
        )
import Json.Decode as JD exposing (field, list, string, bool, maybe, andThen, succeed, fail)
import Json.Encode as JE exposing (Value, object, int)
import Debug exposing (log)
import Dict exposing (Dict, union, fromList)
import List exposing (map)
import String exposing (length)


fetchDocumentTypes : Cmd Msg
fetchDocumentTypes =
    Http.send OnDocumentTypes <| Http.get "http://localhost:4000/api/document-types" documentTypesDecoder


fetchDocuments : Int -> Int -> Cmd Msg
fetchDocuments start length =
    Http.send OnDocuments <| Http.get ("http://localhost:4000/api/documents?start=" ++ toString start ++ "&length=" ++ toString length) documentsDecoder


updateOnDocumentTypes : AppState -> Result Http.Error (List DocumentType) -> AppState
updateOnDocumentTypes model result =
    case result of
        Ok x ->
            { model | documentTypes = x }

        Err _ ->
            model


searchDocuments : String -> Result String (Cmd Msg)
searchDocuments query =
    case (length query) > 1 of
        False ->
            Err "Not enough character to send the query."

        True ->
            Ok (Http.send DidDocumentSearched <| Http.get ("http://localhost:4000/api/documents?query=" ++ query) documentsDecoder)


updateDocuments : Result Http.Error (List Document) -> Maybe (Dict String Document)
updateDocuments result =
    case result of
        Ok x ->
            let
                newDocumentsAsDict =
                    List.map (\y -> ( y.document_id, y )) x |> Dict.fromList
            in
                Just newDocumentsAsDict

        Err _ ->
            Nothing


documentsDecoder : JD.Decoder (List Document)
documentsDecoder =
    (list documentDecoder)


documentTypesDecoder : JD.Decoder (List DocumentType)
documentTypesDecoder =
    (list documentTypeDecoder)


documentTypeDecoder : JD.Decoder DocumentType
documentTypeDecoder =
    JD.map2 DocumentType
        (field "name" string)
        (field "id" string)
