module Documents exposing (getDocuments, handleDocuments, view)

import Html exposing (Html)
import Html.Attributes
import Http
import Iso8601
import Json.Decode
import Models
import String.Format



-- Public members


view : Models.State -> Html Models.Msg
view { documents } =
    let
        count =
            case documents of
                Just x ->
                    x.total

                Nothing ->
                    0
    in
    Html.div []
        [ Html.div [ Html.Attributes.class "row" ]
            [ Html.div [ Html.Attributes.class "col-md-6" ]
                [ Html.span
                    [ Html.Attributes.class "documents align-middle" ]
                    [ Html.text <| String.fromInt count
                    , Html.i
                        [ Html.Attributes.class "fa fa-file highlight"
                        , Html.Attributes.title "Documents"
                        ]
                        []
                    ]
                ]
            , Html.div [ Html.Attributes.class "col-md-6 d-flex" ]
                [ Html.a
                    [ Html.Attributes.class "btn btn-primary ml-auto"
                    , Html.Attributes.href "/documents/add"
                    , Html.Attributes.title "Add documents"
                    ]
                    [ Html.i [ Html.Attributes.class "fa fa-plus" ] [] ]
                ]
            ]
        , Html.hr [ Html.Attributes.style "margin-top" "0.3em" ] []
        ]


handleDocuments : Models.State -> Result Http.Error Models.Documents -> ( Models.State, Cmd Models.Msg )
handleDocuments state result =
    case result of
        Ok x ->
            ( { state | documents = Just x }, Cmd.none )

        Err message ->
            ( { state | error = Just <| httpErrorToString message }, Cmd.none )



-- Private members


httpErrorToString : Http.Error -> String
httpErrorToString error =
    case error of
        Http.BadUrl x ->
            x

        Http.Timeout ->
            "timeout"

        Http.NetworkError ->
            "NetworkError"

        Http.BadStatus x ->
            String.fromInt x

        Http.BadBody x ->
            x


documentDateTimesDecoder : Json.Decode.Decoder Models.DocumentDateTimes
documentDateTimesDecoder =
    Json.Decode.map3 Models.DocumentDateTimes
        (Json.Decode.field "inserted_datetime" Iso8601.decoder)
        (Json.Decode.maybe (Json.Decode.field "updated_datetime" Iso8601.decoder))
        (Json.Decode.field "original_file_datetime" Iso8601.decoder)


documentThumbnails : Json.Decode.Decoder Models.DocumentThumbnails
documentThumbnails =
    Json.Decode.map2 Models.DocumentThumbnails
        (Json.Decode.field "count-images" Json.Decode.int)
        (Json.Decode.maybe (Json.Decode.field "current-image" Json.Decode.int))


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


documentsDecoder : Json.Decode.Decoder Models.Documents
documentsDecoder =
    Json.Decode.map2 Models.Documents
        (Json.Decode.field "documents" (Json.Decode.list documentDecoder))
        (Json.Decode.field "total" Json.Decode.int)


getDocuments : Models.DocumentsRequest -> Cmd Models.Msg
getDocuments { offset, length } =
    Http.get
        { url =
            "/api/documents?offset={{ offset }}&length={{ length }}"
                |> (String.Format.namedValue "offset" <| String.fromInt offset)
                |> (String.Format.namedValue "length" <| String.fromInt length)
        , expect = Http.expectJson Models.GotDocuments documentsDecoder
        }
