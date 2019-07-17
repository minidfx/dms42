module JsonDecoders exposing (..)

import Json.Decode
import Models
import Rfc2822Datetime


tagDecoder : Json.Decode.Decoder Models.DocumentTags
tagDecoder =
    Json.Decode.map2 Models.DocumentTags
        (Json.Decode.field "document_id" Json.Decode.string)
        (Json.Decode.field "tags" (Json.Decode.list Json.Decode.string))


documentsDecoder : Json.Decode.Decoder Models.Documents
documentsDecoder =
    Json.Decode.map2 Models.Documents
        (Json.Decode.field "documents" (Json.Decode.list documentDecoder))
        (Json.Decode.field "total" Json.Decode.int)


documentDecoder : Json.Decode.Decoder Models.Document
documentDecoder =
    Json.Decode.map8 Models.Document
        (Json.Decode.maybe (Json.Decode.field "comments" Json.Decode.string))
        (Json.Decode.field "document_id" Json.Decode.string)
        (Json.Decode.field "document_type_id" Json.Decode.string)
        (Json.Decode.field "tags" (Json.Decode.list Json.Decode.string))
        (Json.Decode.field "original_file_name" Json.Decode.string)
        (Json.Decode.field "datetimes" documentDateTimesDecoder)
        (Json.Decode.field "thumbnails" documentThumbnails)
        (Json.Decode.maybe (Json.Decode.field "ocr" Json.Decode.string))


searchResultDecoder : Json.Decode.Decoder Models.SearchResult
searchResultDecoder =
    Json.Decode.map Models.SearchResult
        (Json.Decode.field "documents" (Json.Decode.list documentDecoder))


documentThumbnails : Json.Decode.Decoder Models.DocumentThumbnails
documentThumbnails =
    Json.Decode.map2 Models.DocumentThumbnails
        (Json.Decode.field "count-images" Json.Decode.int)
        (Json.Decode.maybe (Json.Decode.field "current-image" Json.Decode.int))


documentDateTimesDecoder : Json.Decode.Decoder Models.DocumentDateTimes
documentDateTimesDecoder =
    Json.Decode.map3 Models.DocumentDateTimes
        (Json.Decode.field "inserted_datetime" datetime)
        (Json.Decode.maybe (Json.Decode.field "updated_datetime" datetime))
        (Json.Decode.field "original_file_datetime" datetime)


datetime : Json.Decode.Decoder Rfc2822Datetime.Datetime
datetime =
    let
        convert : String -> Json.Decode.Decoder Rfc2822Datetime.Datetime
        convert raw =
            case Rfc2822Datetime.parse raw of
                Ok x ->
                    Json.Decode.succeed x

                Err error ->
                    Json.Decode.fail error
    in
        Json.Decode.string |> Json.Decode.andThen convert


documentTypesDecoder : Json.Decode.Decoder (List Models.DocumentType)
documentTypesDecoder =
    (Json.Decode.list documentTypeDecoder)


documentTypeDecoder : Json.Decode.Decoder Models.DocumentType
documentTypeDecoder =
    Json.Decode.map2 Models.DocumentType
        (Json.Decode.field "name" Json.Decode.string)
        (Json.Decode.field "id" Json.Decode.string)


ocrResultDecoder : Json.Decode.Decoder Models.DocumentOcr
ocrResultDecoder =
    Json.Decode.map2 Models.DocumentOcr
        (Json.Decode.field "document_id" Json.Decode.string)
        (Json.Decode.field "ocr" Json.Decode.string)


commentsResultDecoder : Json.Decode.Decoder Models.DocumentComments
commentsResultDecoder =
    Json.Decode.map3 Models.DocumentComments
        (Json.Decode.field "document_id" Json.Decode.string)
        (Json.Decode.maybe (Json.Decode.field "comments" Json.Decode.string))
        (Json.Decode.field "updated_datetime" datetime)
