module Views.Home exposing (init, update, view)

import Bootstrap.Alert
import Browser.Dom
import Debounce
import Factories
import Helpers
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Http
import Json.Decode
import Models
import Msgs.Home
import Msgs.Main
import String.Format
import Task
import Url.Builder
import Views.Documents
import Views.Shared



-- Public members


view : Models.State -> List (Html Msgs.Main.Msg)
view ({ searchState } as state) =
    let
        documents =
            searchState
                |> Maybe.andThen (\x -> x.documents)

        query =
            searchState
                |> Maybe.andThen (\x -> x.query)
                |> Maybe.withDefault ""

        content =
            case documents of
                Just x ->
                    if List.isEmpty x then
                        [ Html.div [ Html.Attributes.class "col" ]
                            [ Bootstrap.Alert.simpleWarning [ Html.Attributes.class "text-center" ] [ Html.text "No results found." ] ]
                        ]

                    else
                        [ Html.div [ Html.Attributes.class "col d-flex flex-wrap justify-content-around cards" ] (cards state x)
                        ]

                Nothing ->
                    []
    in
    [ Html.div [ Html.Attributes.class "row" ]
        [ Html.div [ Html.Attributes.class "col home-search" ]
            [ Html.div
                [ Html.Attributes.class "input-group mb-3" ]
                [ Html.input
                    [ Html.Attributes.type_ "search"
                    , Html.Attributes.class "form-control"
                    , Html.Events.onInput <| \x -> (Msgs.Main.HomeMsg << Msgs.Home.UserTypeSearch) <| x
                    , Html.Attributes.value query
                    , Html.Attributes.id "query"
                    ]
                    []
                , Html.span
                    [ Html.Attributes.hidden (searchState == Maybe.Nothing)
                    , Html.Attributes.class "home-search-clear d-flex align-items-center fas fa-times"
                    , Html.Events.onClick <| Msgs.Main.HomeMsg Msgs.Home.Clear
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
    , Html.div [ Html.Attributes.class "row" ] content
    ]


searchDocuments : String -> Cmd Msgs.Main.Msg
searchDocuments query =
    Http.get
        { url = "/api/documents?query={{ }}" |> String.Format.value query
        , expect = Http.expectJson (Msgs.Main.HomeMsg << Msgs.Home.GotSearchResult) (Json.Decode.list Views.Documents.documentDecoder)
        }


handleSearchResult : Models.State -> Result Http.Error (List Models.DocumentResponse) -> ( Models.State, Cmd Msgs.Main.Msg )
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
    ( { state | searchState = Just { searchState | documents = Just documents }, isLoading = False }, Cmd.none )


init : Models.State -> Maybe String -> ( Models.State, Cmd Msgs.Main.Msg )
init state query =
    let
        searchState =
            state.searchState
                |> Maybe.withDefault Factories.searchStateFactory

        newState =
            { state | searchState = Just { searchState | query = query } }
    in
    internalUpdate
        newState
        Msgs.Home.Home


update : Models.State -> Msgs.Home.Msg -> Maybe String -> ( Models.State, Cmd Msgs.Main.Msg )
update state msg query =
    let
        searchState =
            state.searchState
                |> Maybe.withDefault Factories.searchStateFactory

        newState =
            case query of
                Just x ->
                    { state | searchState = Just { searchState | query = Just x } }

                Nothing ->
                    state
    in
    internalUpdate newState msg


debounceConfig : (Debounce.Msg -> Msgs.Main.Msg) -> Debounce.Config Msgs.Main.Msg
debounceConfig debounceMsg =
    { strategy = Debounce.later 500
    , transform = debounceMsg
    }


rankingOrdering : Models.DocumentResponse -> Models.DocumentResponse -> Basics.Order
rankingOrdering a b =
    Basics.compare (Maybe.withDefault 0 <| a.ranking) (Maybe.withDefault 0 <| b.ranking)


cards : Models.State -> List Models.DocumentResponse -> List (Html Msgs.Main.Msg)
cards state documents =
    List.sortWith rankingOrdering documents
        |> List.map (\x -> Views.Shared.card state x)


internalUpdate : Models.State -> Msgs.Home.Msg -> ( Models.State, Cmd Msgs.Main.Msg )
internalUpdate state msg =
    case msg of
        Msgs.Home.GotSearchResult result ->
            handleSearchResult state result

        Msgs.Home.UserTypeSearch query ->
            let
                searchState =
                    Maybe.withDefault Factories.searchStateFactory <| state.searchState

                ( newDebouncer, cmd ) =
                    Debounce.push
                        (debounceConfig <| Msgs.Main.HomeMsg << Msgs.Home.ThrottleSearchDocuments)
                        query
                        searchState.debouncer
            in
            ( { state | searchState = Just { searchState | query = Just query, debouncer = newDebouncer } }
            , cmd
            )

        Msgs.Home.ThrottleSearchDocuments msg_ ->
            let
                searchState =
                    Maybe.withDefault Factories.searchStateFactory <| state.searchState

                ( newDebouncer, cmd ) =
                    Debounce.update
                        (debounceConfig <| Msgs.Main.HomeMsg << Msgs.Home.ThrottleSearchDocuments)
                        (Debounce.takeLast (\x -> searchTo state x))
                        msg_
                        searchState.debouncer
            in
            ( { state | searchState = Just { searchState | debouncer = newDebouncer } }, cmd )

        Msgs.Home.Home ->
            let
                searchState =
                    Maybe.withDefault Factories.searchStateFactory <| state.searchState

                ( newState, newCommands ) =
                    case searchState.query of
                        Just x ->
                            ( { state | isLoading = True }, [ searchDocuments x ] )

                        Nothing ->
                            ( state, [ Task.attempt (\_ -> Msgs.Main.Nop) (Browser.Dom.focus "query") ] )
            in
            ( newState, Cmd.batch newCommands )

        Msgs.Home.Clear ->
            ( { state | searchState = Nothing }, Cmd.none )

        _ ->
            ( state, Cmd.none )


searchTo : Models.State -> String -> Cmd Msgs.Main.Msg
searchTo state query =
    Task.perform Msgs.Main.LinkClicked (Task.succeed <| Helpers.navTo state [] [ Url.Builder.string "query" query ])
