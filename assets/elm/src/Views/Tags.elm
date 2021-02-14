module Views.Tags exposing (init, update, view)

-- Public members

import Bootstrap.Alert
import Bootstrap.Spinner
import Bootstrap.Text
import Browser.Navigation as Nav
import Factories
import Helpers
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Http
import Json.Decode
import Models
import Msgs.Main
import Msgs.Tags
import Set
import Simple.Fuzzy
import String.Format
import Task
import Views.Documents
import Views.Shared


init : () -> Nav.Key -> Models.State -> ( Models.State, Cmd Msgs.Main.Msg )
init _ _ state =
    ( state, Views.Shared.getTags )


update : Models.State -> Msgs.Tags.Msg -> ( Models.State, Cmd Msgs.Main.Msg )
update state msg =
    case msg of
        Msgs.Tags.Home ->
            let
                tags =
                    state.tagsState
                        |> Maybe.withDefault Factories.tagsStateFactory
                        |> Helpers.fluentSelect (\x -> x.selected)
                        |> Set.toList
            in
            ( state, Cmd.batch [ Views.Shared.getTags, searchDocuments tags ] )

        Msgs.Tags.ToggleTag tag ->
            let
                tags =
                    state.tagsResponse
                        |> Maybe.withDefault []
                        |> Set.fromList

                tagsState =
                    state.tagsState
                        |> Maybe.withDefault Factories.tagsStateFactory
                        |> Helpers.fluentUpdate (\x -> { x | selected = Set.intersect x.selected tags })

                ( tagsSelected, newState ) =
                    if Set.member tag tagsState.selected then
                        ( Set.remove tag tagsState.selected
                        , { state | tagsState = Just { tagsState | selected = Set.remove tag tagsState.selected } }
                        )

                    else
                        ( Set.insert tag tagsState.selected
                        , { state | tagsState = Just { tagsState | selected = Set.insert tag tagsState.selected } }
                        )
            in
            ( { newState | isLoading = True }
            , tagsSelected
                |> Set.toList
                |> searchDocuments
            )

        Msgs.Tags.GotSearchResult result ->
            let
                documents =
                    case result of
                        Ok x ->
                            x

                        Err _ ->
                            []

                tagsState =
                    state.tagsState
                        |> Maybe.withDefault Factories.tagsStateFactory

                newState =
                    { state | tagsState = Just { tagsState | documents = Just documents }, isLoading = False }
            in
            ( newState, Cmd.none )

        Msgs.Tags.CleanResult ->
            let
                tagsState =
                    state.tagsState
                        |> Maybe.withDefault Factories.tagsStateFactory
            in
            ( { state | tagsState = Just { tagsState | documents = Nothing }, isLoading = False }, Cmd.none )

        Msgs.Tags.UserTypeFilter filter ->
            let
                tagsState =
                    state.tagsState
                        |> Maybe.withDefault Factories.tagsStateFactory
            in
            ( { state | tagsState = Just { tagsState | filter = Just filter } }, Cmd.none )

        Msgs.Tags.Clear ->
            let
                tagsState =
                    state.tagsState
                        |> Maybe.withDefault Factories.tagsStateFactory
            in
            ( { state | tagsState = Just { tagsState | filter = Nothing } }, Cmd.none )

        Msgs.Tags.Nop ->
            ( state, Cmd.none )


view : Models.State -> List (Html Msgs.Main.Msg)
view ({ tagsState, tagsResponse, isLoading } as state) =
    let
        localTagsState =
            tagsState
                |> Maybe.withDefault Factories.tagsStateFactory

        tagsFilter =
            localTagsState
                |> Helpers.fluentSelect (\x -> x.filter)
                |> Maybe.withDefault ""
                |> String.trim

        documents =
            localTagsState.documents |> Maybe.withDefault []

        content =
            -- (isEmpty, isLoading)
            case ( List.isEmpty documents, isLoading ) of
                ( True, True ) ->
                    [ Html.div [ Html.Attributes.class "col" ]
                        [ Html.div [ Html.Attributes.class "d-flex" ]
                            [ Bootstrap.Spinner.spinner
                                [ Bootstrap.Spinner.large
                                , Bootstrap.Spinner.color Bootstrap.Text.primary
                                , Bootstrap.Spinner.attrs [ Html.Attributes.class "mx-auto" ]
                                ]
                                [ Bootstrap.Spinner.srMessage "Loading ..." ]
                            ]
                        ]
                    ]

                ( False, False ) ->
                    [ Html.div [ Html.Attributes.class "col d-flex justify-content-around flex-wrap cards" ]
                        (Views.Documents.cards state documents)
                    ]

                ( True, False ) ->
                    [ Html.div [ Html.Attributes.class "col" ]
                        [ Bootstrap.Alert.simpleInfo [ Html.Attributes.class "text-center" ]
                            [ Html.text "Select a tag"
                            , Html.i
                                [ Html.Attributes.class "fas fa-hand-point-up"
                                , Html.Attributes.class "ml-2"
                                ]
                                []
                            ]
                        ]
                    ]

                ( False, True ) ->
                    [ Html.div [ Html.Attributes.class "col d-flex justify-content-around flex-wrap cards" ]
                        (Views.Documents.cards state documents)
                    ]
    in
    [ Html.div [ Html.Attributes.class "row" ]
        [ Html.div [ Html.Attributes.class "col d-flex flex-row-reverse query-text" ]
            [ Html.div
                [ Html.Attributes.class "input-group mb-3 w-25"
                ]
                [ Html.input
                    [ Html.Attributes.type_ "search"
                    , Html.Attributes.class "form-control"
                    , Html.Attributes.id "tags-query"
                    , Html.Attributes.placeholder "filter"
                    , Html.Attributes.value tagsFilter
                    , Html.Events.onInput <| \x -> (Msgs.Main.TagsMsg << Msgs.Tags.UserTypeFilter) <| x
                    ]
                    []
                , Html.span
                    [ Html.Attributes.hidden (tagsFilter |> String.isEmpty)
                    , Html.Attributes.class "query-clear d-flex align-items-center fas fa-times"
                    , Html.Events.onClick <| Msgs.Main.TagsMsg Msgs.Tags.Clear
                    ]
                    []
                , Html.div [ Html.Attributes.class "input-group-append" ]
                    [ Html.span [ Html.Attributes.class "input-group-text" ]
                        [ Html.i [ Html.Attributes.class "fas fa-filter" ] []
                        ]
                    ]
                ]
            ]
        ]
    , filterTags state
    , Html.hr [ Html.Attributes.style "margin-top" "0.3em" ] []
    , Html.div [ Html.Attributes.class "row documents" ] content
    ]



-- Private members


filterTags : Models.State -> Html Msgs.Main.Msg
filterTags ({ tagsResponse, tagsState } as state) =
    let
        allTags =
            tagsResponse |> Maybe.withDefault []

        tags =
            if String.isEmpty tagsFilter then
                allTags

            else
                allTags
                    |> Simple.Fuzzy.filter (\x -> x) tagsFilter

        localTagsState =
            tagsState
                |> Maybe.withDefault Factories.tagsStateFactory

        tagsFilter =
            localTagsState |> Helpers.fluentSelect (\x -> x.filter) |> Maybe.withDefault ""
    in
    Html.div [ Html.Attributes.class "row" ]
        [ Html.div [ Html.Attributes.class "col tags d-flex justify-content-center flex-wrap" ]
            (tags
                |> List.sort
                |> List.map (\x -> badge state x)
            )
        ]


badge : Models.State -> String -> Html Msgs.Main.Msg
badge { isLoading, tagsState } tag =
    case isLoading of
        True ->
            Html.span
                [ Html.Attributes.class "badge badge-light badge-pointer-not-allowed user-select-none"
                ]
                [ Html.text tag ]

        False ->
            let
                localTagsState =
                    tagsState
                        |> Maybe.withDefault Factories.tagsStateFactory

                badgeStyles =
                    if Set.member tag localTagsState.selected then
                        "badge badge-success badge-pointer user-select-none"

                    else
                        "badge badge-secondary badge-pointer user-select-none"
            in
            Html.span
                [ Html.Attributes.class badgeStyles
                , Html.Events.onClick <| (Msgs.Main.TagsMsg << Msgs.Tags.ToggleTag) <| tag
                ]
                [ Html.text tag ]


searchDocuments : List String -> Cmd Msgs.Main.Msg
searchDocuments tags =
    let
        queryTags =
            List.map (\x -> "tags[]={{ }}" |> String.Format.value x) tags
                |> String.join "&"
    in
    case tags of
        [] ->
            Task.perform identity <| Task.succeed (Msgs.Main.TagsMsg Msgs.Tags.CleanResult)

        _ ->
            Http.get
                { url = "/api/documents?{{ }}" |> String.Format.value queryTags
                , expect = Http.expectJson (Msgs.Main.TagsMsg << Msgs.Tags.GotSearchResult) (Json.Decode.list Views.Documents.documentDecoder)
                }
