module Views.Documents exposing (cards, documentDecoder, getDocuments, handleDocuments, init, update, view)

import Bootstrap.Spinner
import Bootstrap.Text
import Browser.Navigation as Nav
import Dict exposing (Dict)
import Factories
import Helpers exposing (httpErrorToString)
import Html exposing (Html)
import Html.Attributes
import Http
import Iso8601
import Json.Decode
import Models
import String.Format
import Views.Shared



-- Public members


init : () -> Nav.Key -> Models.State -> Maybe Int -> ( Models.State, Cmd Models.Msg )
init _ _ initialState offset =
    internalUpdate initialState offset


update : Models.State -> Maybe Int -> ( Models.State, Cmd Models.Msg )
update state offset =
    internalUpdate state offset


view : Models.State -> Maybe Int -> List (Html Models.Msg)
view state offset =
    let
        documentsState =
            state.documentsState
                |> Maybe.withDefault Factories.documentsStateFactory

        { total } =
            documentsState

        documents =
            documentsState.documents
                |> Maybe.withDefault Dict.empty

        showLoading =
            state.isLoading && total < 1

        content =
            case showLoading of
                True ->
                    [ Html.div [ Html.Attributes.class "d-flex" ]
                        [ Html.div [ Html.Attributes.class "ml-auto mr-auto" ]
                            [ Bootstrap.Spinner.spinner
                                [ Bootstrap.Spinner.large
                                , Bootstrap.Spinner.color Bootstrap.Text.primary
                                , Bootstrap.Spinner.attrs [ Html.Attributes.class "m-5" ]
                                ]
                                [ Bootstrap.Spinner.srMessage "Loading ..." ]
                            ]
                        ]
                    ]

                False ->
                    internalDocumentsView state (Dict.values documents) offset

        topLeftStatus =
            case state.isLoading && total > 0 of
                True ->
                    [ Html.span
                        [ Html.Attributes.class "documents" ]
                        [ Html.text <| String.fromInt <| total
                        , Html.i
                            [ Html.Attributes.class "fa fa-file highlight"
                            , Html.Attributes.title "Documents"
                            ]
                            []
                        ]
                    , Bootstrap.Spinner.spinner
                        [ Bootstrap.Spinner.small
                        , Bootstrap.Spinner.color Bootstrap.Text.primary
                        , Bootstrap.Spinner.attrs
                            [ Html.Attributes.class "ml-2"
                            ]
                        ]
                        [ Bootstrap.Spinner.srMessage "Loading ..." ]
                    ]

                False ->
                    [ Html.span
                        [ Html.Attributes.class "documents" ]
                        [ Html.text <| String.fromInt <| total
                        , Html.i
                            [ Html.Attributes.class "fa fa-file highlight"
                            , Html.Attributes.title "Documents"
                            ]
                            []
                        ]
                    ]
    in
    [ Html.div [ Html.Attributes.class "row" ]
        [ Html.div [ Html.Attributes.class "col-6 d-flex align-items-center" ]
            topLeftStatus
        , Html.div [ Html.Attributes.class "col-6 d-flex" ]
            [ Html.a
                [ Html.Attributes.class "btn btn-primary ml-auto"
                , Html.Attributes.href "/documents/add"
                , Html.Attributes.title "Add documents"
                ]
                [ Html.i [ Html.Attributes.class "fa fa-plus" ] [] ]
            ]
        ]
    , Html.hr [ Html.Attributes.style "margin-top" "0.3em" ] []
    , Html.div [ Html.Attributes.class "row documents" ]
        [ Html.div [ Html.Attributes.class "col" ] content
        ]
    ]


cards : Models.State -> List Models.DocumentResponse -> List (Html Models.Msg)
cards state documents =
    List.map (\x -> Views.Shared.card state x) documents


handleDocuments : Models.State -> Result Http.Error Models.DocumentsResponse -> ( Models.State, Cmd Models.Msg )
handleDocuments state result =
    let
        stateWithoutLoading =
            { state | isLoading = False }
    in
    case result of
        Ok response ->
            let
                { total, documents } =
                    response

                documentsDictionarized =
                    documents |> List.map (\x -> ( x.id, x )) |> Dict.fromList

                documentsState =
                    stateWithoutLoading.documentsState
                        |> Maybe.withDefault Factories.documentsStateFactory
                        |> Helpers.fluentUpdate (\x -> { x | documents = Just documentsDictionarized, total = total })
            in
            ( { stateWithoutLoading | documentsState = Just documentsState }, Cmd.none )

        Err message ->
            ( { stateWithoutLoading | error = Just <| httpErrorToString message, documentsState = Nothing }
            , Cmd.none
            )


getDocuments : Models.DocumentsRequest -> Cmd Models.Msg
getDocuments { offset, length } =
    Http.get
        { url =
            "/api/documents?offset={{ offset }}&length={{ length }}"
                |> (String.Format.namedValue "offset" <| String.fromInt offset)
                |> (String.Format.namedValue "length" <| String.fromInt length)
        , expect = Http.expectJson Models.GotDocuments documentsDecoder
        }


documentDecoder : Json.Decode.Decoder Models.DocumentResponse
documentDecoder =
    Json.Decode.map8 Models.DocumentResponse
        (Json.Decode.maybe (Json.Decode.field "comments" Json.Decode.string))
        (Json.Decode.field "document_id" Json.Decode.string)
        (Json.Decode.field "document_type_id" Json.Decode.string)
        (Json.Decode.field "tags" (Json.Decode.list Json.Decode.string))
        (Json.Decode.field "original_file_name" Json.Decode.string)
        (Json.Decode.field "datetimes" documentDateTimesDecoder)
        (Json.Decode.field "thumbnails" documentThumbnails)
        (Json.Decode.maybe (Json.Decode.field "ocr" Json.Decode.string))



-- Private members


internalDocumentsView : Models.State -> List Models.DocumentResponse -> Maybe Int -> List (Html Models.Msg)
internalDocumentsView state documents offset =
    let
        documentsState =
            Maybe.withDefault Factories.documentsStateFactory <| state.documentsState

        { total, length } =
            documentsState

        pagination =
            Views.Shared.pagination
                total
                length
                offset
                (\x -> "/documents?offset={{ }}" |> (String.Format.value <| String.fromInt <| (*) x length))
    in
    if List.isEmpty documents |> not then
        [ pagination
        , Html.div [ Html.Attributes.class "cards d-flex justify-content-start flex-wrap" ] (cards state documents)
        , pagination
        ]

    else
        [ Html.div [ Html.Attributes.class "d-flex" ]
            [ Html.div [ Html.Attributes.class "ml-auto mr-auto media position-relative empty" ]
                [ Html.i
                    [ Html.Attributes.class "fas fa-otter"
                    , Html.Attributes.title "No documents"
                    ]
                    []
                ]
            ]
        ]


internalUpdate : Models.State -> Maybe Int -> ( Models.State, Cmd Models.Msg )
internalUpdate state offset =
    let
        documentsState =
            Maybe.withDefault Factories.documentsStateFactory <| state.documentsState

        { length } =
            documentsState

        localOffset =
            Maybe.withDefault 0 <| offset
    in
    ( { state | isLoading = True }
    , Cmd.batch [ getDocuments { offset = localOffset, length = length } ]
    )


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


documentsDecoder : Json.Decode.Decoder Models.DocumentsResponse
documentsDecoder =
    Json.Decode.map2 Models.DocumentsResponse
        (Json.Decode.field "documents" (Json.Decode.list documentDecoder))
        (Json.Decode.field "total" Json.Decode.int)
