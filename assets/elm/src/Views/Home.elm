module Views.Home exposing (handleSearchResult, init, searchDocuments, update, view)

import Browser.Dom
import Factories
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Http
import Json.Decode
import Models
import String.Format
import Task
import Views.Documents
import Views.Shared



-- Public members


view : Models.State -> List (Html Models.Msg)
view state =
    let
        searchState =
            Maybe.withDefault Factories.searchStateFactory <| state.searchState

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
                    , Html.Attributes.value <| Maybe.withDefault "" <| searchState.query
                    , Html.Attributes.id "query"
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
        [ Html.div [ Html.Attributes.class "col d-flex flex-wrap cards" ] (cards state documents)
        ]
    ]


searchDocuments : Models.State -> Maybe String -> ( Models.State, Cmd Models.Msg )
searchDocuments state query =
    let
        queryClean =
            case query of
                Just x ->
                    if String.length x <= 2 then
                        Nothing

                    else
                        query

                Nothing ->
                    Nothing
    in
    case queryClean of
        Nothing ->
            ( state, Cmd.none )

        Just x ->
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


init : Models.State -> Maybe String -> ( Models.State, Cmd Models.Msg )
init state query =
    internalUpdate state query


update : Models.State -> Maybe String -> ( Models.State, Cmd Models.Msg )
update state query =
    internalUpdate state query



-- Private members


rankingOrdering : Models.DocumentResponse -> Models.DocumentResponse -> Basics.Order
rankingOrdering a b =
    Basics.compare (Maybe.withDefault 0 <| a.ranking) (Maybe.withDefault 0 <| b.ranking)


cards : Models.State -> List Models.DocumentResponse -> List (Html Models.Msg)
cards state documents =
    List.sortWith rankingOrdering documents
        |> List.map (\x -> Views.Shared.card state x)


internalUpdate : Models.State -> Maybe String -> ( Models.State, Cmd Models.Msg )
internalUpdate state query =
    let
        searchState =
            Maybe.withDefault Factories.searchStateFactory <| state.searchState

        newState =
            case query of
                Just x ->
                    { state | searchState = Just { searchState | query = Just x } }

                Nothing ->
                    state

        ( searchStateUpdated, searchStateCmds ) =
            searchDocuments newState query
    in
    ( searchStateUpdated, Cmd.batch [ searchStateCmds, Task.attempt (\_ -> Models.Nop) (Browser.Dom.focus "query") ] )
