module Updates.Documents exposing (updateDocumentTypes)

import Models.Application exposing (DocumentType, Msg)
import Json.Decode as JD exposing (field, list, string, bool, maybe)
import Json.Encode as JE exposing (Value)
import Debug exposing (log)


updateDocumentTypes : Models.Application.AppModel -> JE.Value -> Models.Application.AppModel
updateDocumentTypes model json =
    let
        documentTypes =
            log "json" (JD.decodeValue documentTypesDecoder json)
    in
        case documentTypes of
            Ok x ->
                { model | documentTypes = x }

            Err _ ->
                model


documentTypesDecoder : JD.Decoder (List DocumentType)
documentTypesDecoder =
    (field "document-types" (list documentTypeDecoder))


documentTypeDecoder : JD.Decoder DocumentType
documentTypeDecoder =
    JD.map2 DocumentType
        (field "name" string)
        (field "id" string)
