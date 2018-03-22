module Updates.Document exposing (updateDocument, createTag, deleteTag, deleteDocument)

import Models exposing (AppState, Msg)
import Json.Encode
import Models
    exposing
        ( Msg(PhoenixMsg, OnDocuments, OnDocumentTypes, DidTagCreated, DidTagDeleted, DidDocumentDeleted)
        , DocumentId
        , DidDocumentDeletedResponse
        )
import Http exposing (request, getString)
import Json.Decode as JD exposing (field, string)


updateDocument : AppState -> Json.Encode.Value -> AppState
updateDocument model json =
    model


createTag : String -> String -> Cmd Msg
createTag document_id tag =
    let
        request =
            Http.request
                { method = "POST"
                , url = "http://localhost:4000/api/documents/" ++ document_id ++ "/tags/" ++ tag
                , body = Http.emptyBody
                , timeout = Nothing
                , headers = []
                , expect = Http.expectStringResponse (\_ -> Ok ())
                , withCredentials = False
                }
    in
        Http.send DidTagCreated <| request


deleteTag : String -> String -> Cmd Msg
deleteTag document_id tag =
    let
        request =
            Http.request
                { method = "DELETE"
                , url = "http://localhost:4000/api/documents/" ++ document_id ++ "/tags/" ++ tag
                , body = Http.emptyBody
                , timeout = Nothing
                , headers = []
                , expect = Http.expectStringResponse (\_ -> Ok ())
                , withCredentials = False
                }
    in
        Http.send DidTagDeleted <| request


didDocumentDeletedDecoder : JD.Decoder DidDocumentDeletedResponse
didDocumentDeletedDecoder =
    JD.map DidDocumentDeletedResponse
        (field "document_id" string)


deleteDocument : DocumentId -> Cmd Msg
deleteDocument document_id =
    let
        request =
            Http.request
                { method = "DELETE"
                , url = "http://localhost:4000/api/documents/" ++ document_id
                , body = Http.emptyBody
                , timeout = Nothing
                , headers = []
                , expect = Http.expectJson didDocumentDeletedDecoder
                , withCredentials = False
                }
    in
        Http.send DidDocumentDeleted <| request
