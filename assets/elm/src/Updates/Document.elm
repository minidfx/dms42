module Updates.Document exposing (..)

import Models exposing (AppState, Msg)
import Json.Encode
import Models
    exposing
        ( Msg
            ( OnDocuments
            , OnDocument
            , OnDocumentTypes
            , DidTagCreated
            , DidTagDeleted
            , DidDocumentDeleted
            )
        , DocumentId
        , DidDocumentDeletedResponse
        , DocumentDateTimes
        , Document
        )
import Http exposing (request, getString)
import Json.Decode as JD exposing (field, list, string, int, bool, maybe, andThen, succeed, fail)
import Rfc2822Datetime exposing (..)
import Dict


updateDocument : AppState -> Result Http.Error Document -> AppState
updateDocument model result =
    case result of
        Ok x ->
            let
                newDocumentsAsDict =
                    List.map (\y -> ( y.document_id, y )) [ x ] |> Dict.fromList

                unionDocuments =
                    case model.documents of
                        Just x ->
                            Dict.union x newDocumentsAsDict

                        Nothing ->
                            Dict.empty
            in
                { model | documents = Just unionDocuments }

        Err _ ->
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


fetchDocument : String -> Cmd Msg
fetchDocument documentId =
    Http.send OnDocument <| Http.get ("http://localhost:4000/api/documents/" ++ documentId) documentDecoder


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


documentDecoder : JD.Decoder Document
documentDecoder =
    JD.map8 Document
        (field "comments" string)
        (field "document_id" string)
        (field "document_type_id" string)
        (field "tags" (list string))
        (field "original_file_name" string)
        (field "datetimes" documentDateTimesDecoder)
        (field "count_images" int)
        (maybe (field "ocr" string))


documentDateTimesDecoder : JD.Decoder DocumentDateTimes
documentDateTimesDecoder =
    JD.map3 DocumentDateTimes
        (field "inserted_datetime" datetime)
        (field "updated_datetime" datetime)
        (field "original_file_datetime" datetime)


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
