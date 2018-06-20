module Helpers exposing (..)

import Html exposing (Html)
import Html.Attributes
import Models
import Task
import Dict exposing (Dict)


script : String -> Html Models.Msg
script code =
    Html.node "script" [ Html.Attributes.type_ "text/javascript" ] [ Html.text code ]


sendMsg : Models.Msg -> Cmd Models.Msg
sendMsg msg =
    Task.succeed msg |> Task.perform identity


mergeDocument : Models.Document -> Maybe (Dict String Models.Document) -> Dict String Models.Document
mergeDocument newDocument documents =
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
