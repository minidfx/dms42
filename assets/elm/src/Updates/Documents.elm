module Updates.Documents exposing (updateDocumentTypes, updateDocuments)

import Rfc2822Datetime exposing (..)
import Models.Application exposing (DocumentType, Document, Msg)
import Json.Decode as JD exposing (field, list, string, bool, maybe, andThen, succeed, fail)
import Json.Encode as JE exposing (Value)
import Debug exposing (log)


updateDocumentTypes : Models.Application.AppModel -> JE.Value -> Models.Application.AppModel
updateDocumentTypes model json =
    let
        documentTypes =
            JD.decodeValue documentTypesDecoder json
    in
        case documentTypes of
            Ok x ->
                { model | documentTypes = x }

            Err _ ->
                model


updateDocuments : Models.Application.AppModel -> JE.Value -> Models.Application.AppModel
updateDocuments model json =
    let
        documents =
            JD.decodeValue documentsDecoder json
    in
        case documents of
            Ok x ->
                { model | documents = x }

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
    (field "documents" (list documentDecoder))


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
    (field "document_types" (list documentTypeDecoder))


documentTypeDecoder : JD.Decoder DocumentType
documentTypeDecoder =
    JD.map2 DocumentType
        (field "name" string)
        (field "id" string)
