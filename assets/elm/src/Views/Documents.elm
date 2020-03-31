module Views.Documents exposing (getDocuments, handleDocuments, init, update, view)

import Bootstrap.Pagination
import Bootstrap.Pagination.Item
import Browser
import Browser.Navigation as Nav
import Dict
import Factories
import Helpers exposing (httpErrorToString)
import Html exposing (Html)
import Html.Attributes
import Http
import Iso8601
import Json.Decode
import Models
import String.Format
import Url exposing (Url)
import Url.Builder
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
    in
    [ Html.div [ Html.Attributes.class "row" ]
        [ Html.div [ Html.Attributes.class "col-md-6" ]
            [ Html.span
                [ Html.Attributes.class "documents align-middle" ]
                [ Html.text <| String.fromInt <| total
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
    , Html.div [ Html.Attributes.class "row" ]
        [ Html.div [ Html.Attributes.class "cards d-flex justify-content-center flex-wrap" ] (cards state (Dict.values documents) [])
        ]
    , Html.div [ Html.Attributes.class "row d-flex align-items-start" ]
        [ pagination state offset
        ]
    ]


cards : Models.State -> List Models.DocumentResponse -> List (Html Models.Msg) -> List (Html Models.Msg)
cards state documents acc =
    case documents of
        [] ->
            acc

        head :: tail ->
            cards state tail (Views.Shared.card state head :: acc)


handleDocuments : Models.State -> Result Http.Error Models.DocumentsResponse -> ( Models.State, Cmd Models.Msg )
handleDocuments state result =
    case result of
        Ok response ->
            let
                { total, documents } =
                    response

                documentsDictionarized =
                    documents |> List.map (\x -> ( x.id, x )) |> Dict.fromList

                documentsState =
                    state.documentsState
                        |> Maybe.withDefault Factories.documentsStateFactory
                        |> Helpers.fluentUpdate (\x -> { x | documents = Just documentsDictionarized, total = total })
            in
            ( { state | documentsState = Just documentsState }, Cmd.none )

        Err message ->
            ( { state | error = Just <| httpErrorToString message, documentsState = Nothing }
            , Cmd.none
            )



-- Private members


internalUpdate : Models.State -> Maybe Int -> ( Models.State, Cmd Models.Msg )
internalUpdate state offset =
    let
        request =
            { offset = Maybe.withDefault 0 offset, length = 10 }

        documentsState =
            state.documentsState
                |> Maybe.withDefault Factories.documentsStateFactory
                |> Helpers.fluentUpdate (\x -> { x | documentsRequest = Just request, length = request.length })
    in
    ( { state | documentsState = Just documentsState }
    , Cmd.batch [ getDocuments request ]
    )


paginationItems : Models.State -> Maybe Int -> Bootstrap.Pagination.ListConfig Int Models.Msg
paginationItems state offset =
    let
        localOffset =
            Maybe.withDefault 0 offset

        documentsState =
            Maybe.withDefault Factories.documentsStateFactory <| state.documentsState

        { total, length } =
            documentsState
    in
    { selectedMsg = \x -> Models.None
    , prevItem = Just <| Bootstrap.Pagination.ListItem [] [ Html.text "Previous" ]
    , nextItem = Just <| Bootstrap.Pagination.ListItem [] [ Html.text "Next" ]
    , activeIdx = (//) ((-) localOffset -1) length
    , data = List.range 0 <| (//) total length
    , itemFn = \x _ -> Bootstrap.Pagination.ListItem [] [ Html.text <| String.fromInt <| (+) x 1 ]
    , urlFn = \x _ -> "/documents?offset={{ }}" |> (String.Format.value <| String.fromInt <| (*) x length)
    }


pagination : Models.State -> Maybe Int -> Html Models.Msg
pagination state offset =
    Bootstrap.Pagination.defaultConfig
        |> Bootstrap.Pagination.listAttrs [ Html.Attributes.class "ml-auto mr-auto" ]
        |> Bootstrap.Pagination.ariaLabel "documents-pagination"
        |> Bootstrap.Pagination.itemsList (paginationItems state offset)
        |> Bootstrap.Pagination.view


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


documentsDecoder : Json.Decode.Decoder Models.DocumentsResponse
documentsDecoder =
    Json.Decode.map2 Models.DocumentsResponse
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
