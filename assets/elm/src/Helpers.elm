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


safeValue : Maybe x -> x -> x
safeValue maybeValue default =
    case maybeValue of
        Nothing ->
            default

        Just x ->
            x


sendMsg : Models.Msg -> Cmd Models.Msg
sendMsg msg =
    Task.succeed msg |> Task.perform identity


mergeDocument : Maybe (Dict String Models.Document) -> Models.Document -> Dict String Models.Document
mergeDocument documents newDocument =
    mergeDocuments [ newDocument ] documents


mergeDocuments : List Models.Document -> Maybe (Dict String Models.Document) -> Dict String Models.Document
mergeDocuments newDocuments documents =
    case documents of
        Nothing ->
            newDocuments |> documentsToDict

        Just x ->
            Dict.union (newDocuments |> documentsToDict) x


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


getDocumentTypeId : Models.AppState -> String -> Models.DocumentType
getDocumentTypeId state document_type_id =
    let
        default =
            { name = "Unknown document type", id = "no-id" }
    in
        case state.documentTypes of
            Nothing ->
                default

            Just x ->
                safeValue (x |> List.filter (\x -> x.id == document_type_id) |> List.head) default


debounce : Models.Msg -> Models.Msg
debounce =
    Debounce.trailing Models.Debouncer (Time.inMilliseconds 500)
