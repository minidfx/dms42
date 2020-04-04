module Views.Home exposing (handleSearchResult, searchDocuments, view)

import Factories
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Http
import Json.Decode
import Models
import String.Format
import Views.Documents



-- Public members


view : Models.State -> List (Html Models.Msg)
view state =
    let
        searchState =
            Maybe.withDefault Factories.searchStateFactory <| state.searchState

        query =
            Maybe.withDefault "" <| searchState.query

        documents =
            Maybe.withDefault [] searchState.documents
    in
    [ Html.div [ Html.Attributes.class "row" ]
        [ Html.div [ Html.Attributes.class "col home-search" ]
            [ Html.div
                [ Html.Attributes.class "input-group mb-3" ]
                [ Html.input
                    [ Html.Attributes.type_ "text"
                    , Html.Attributes.class "form-control"
                    , Html.Events.onInput <| \x -> Models.UserTypeSearch x
                    , Html.Attributes.value query
                    ]
                    []
                , Html.div [ Html.Attributes.class "input-group-append" ]
                    [ Html.span [ Html.Attributes.class "input-group-text" ]
                        [ Html.i [ Html.Attributes.class "fas fa-search" ] []
                        ]
                    ]
                ]
            ]
        ]
    , Html.div [ Html.Attributes.class "row" ]
        [ Html.div [ Html.Attributes.class "col d-flex flex-wrap cards" ] (Views.Documents.cards state documents)
        ]
    ]


searchDocuments : Models.State -> String -> ( Models.State, Cmd Models.Msg )
searchDocuments state query =
    let
        queryClean =
            if String.length query <= 2 then
                ""

            else
                query
    in
    case queryClean of
        "" ->
            ( state, Cmd.none )

        x ->
            ( state
            , Http.get
                { url = "/api/documents?query={{ }}" |> String.Format.value x
                , expect = Http.expectJson Models.GotSearchResult (Json.Decode.list Views.Documents.documentDecoder)
                }
            )


handleSearchResult : Models.State -> Result Http.Error (List Models.DocumentResponse) -> ( Models.State, Cmd Models.Msg )
handleSearchResult state result =
    let
        searchState =
            Maybe.withDefault Factories.searchStateFactory <| state.searchState

        documents =
            case result of
                Ok x ->
                    x

                Err _ ->
                    []
    in
    ( { state | searchState = Just { searchState | documents = Just documents } }, Cmd.none )
