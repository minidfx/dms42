module Updates.Documents exposing (updateOnDocumentTypes, updateDocuments, fetchDocuments, fetchDocumentTypes)

import Rfc2822Datetime exposing (..)
import Http exposing (request, getString)
import Models exposing (AppState, DocumentType, Document, Msg, Msg(PhoenixMsg, OnDocuments, OnDocumentTypes))
import Json.Decode as JD exposing (field, list, string, bool, maybe, andThen, succeed, fail)
import Json.Encode as JE exposing (Value, object, int)
import Debug exposing (log)
import Phoenix.Socket exposing (Socket, push)
import Phoenix.Push exposing (withPayload)
import Dict exposing (Dict, union, fromList)
import List exposing (map)


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


updateDocuments : AppState -> Result Http.Error (List Document) -> AppState
updateDocuments model result =
    case result of
        Ok x ->
            let
                newDocumentsAsDict =
                    List.map (\y -> ( y.document_id, y )) x |> Dict.fromList

                documents =
                    case model.documents of
                        Nothing ->
                            [] |> Dict.fromList

                        Just x ->
                            x

                newDocuments =
                    Dict.union newDocumentsAsDict documents
            in
                { model | documents = Just newDocuments }

        Err _ ->
            model


datetime : JD.Decoder Datetime
datetime =
    let
        convert : String -> JD.Decoder Datetime
        convert raw =
            case Rfc2822Datetime.parse raw of
                Ok x ->
                    succeed x

                Err error ->
                    fail error
    in
        string |> andThen convert


documentsDecoder : JD.Decoder (List Document)
documentsDecoder =
    (list documentDecoder)


documentDecoder : JD.Decoder Document
documentDecoder =
    JD.map6 Document
        (field "thumbnailPath" string)
        (field "insertedAt" datetime)
        (field "updatedAt" datetime)
        (field "comments" string)
        (field "document_id" string)
        (field "document_type_id" string)


documentTypesDecoder : JD.Decoder (List DocumentType)
documentTypesDecoder =
    (list documentTypeDecoder)


documentTypeDecoder : JD.Decoder DocumentType
documentTypeDecoder =
    JD.map2 DocumentType
        (field "name" string)
        (field "id" string)
