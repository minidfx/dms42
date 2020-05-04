module Views.Tags exposing (init, update, view)

-- Public members

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
            ( state, Views.Shared.getTags )

        Msgs.Tags.ToggleTag tag ->
            let
                tagsState =
                    state.tagsState
                        |> Maybe.withDefault Factories.tagsStateFactory

                newState =
                    if Set.member tag tagsState.selected then
                        { state | tagsState = Just { tagsState | selected = Set.remove tag tagsState.selected } }

                    else
                        { state | tagsState = Just { tagsState | selected = Set.insert tag tagsState.selected } }

                tags =
                    newState.tagsState
                        |> Maybe.withDefault Factories.tagsStateFactory
                        |> Helpers.fluentSelect (\x -> x.selected)
                        |> Set.toList
            in
            ( newState, searchDocuments tags )

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
                    { state | tagsState = Just { tagsState | documents = Just documents } }
            in
            ( newState, Cmd.none )

        Msgs.Tags.CleanResult ->
            let
                tagsState =
                    state.tagsState
                        |> Maybe.withDefault Factories.tagsStateFactory
            in
            ( { state | tagsState = Just { tagsState | documents = Nothing } }, Cmd.none )

        Msgs.Tags.Nop ->
            ( state, Cmd.none )


view : Models.State -> List (Html Msgs.Main.Msg)
view state =
    let
        { tagsResponse } =
            state

        tags =
            tagsResponse |> Maybe.withDefault []

        tagsState =
            state.tagsState
                |> Maybe.withDefault Factories.tagsStateFactory

        documents =
            tagsState.documents |> Maybe.withDefault []
    in
    [ Html.div [ Html.Attributes.class "row" ]
        [ Html.div [ Html.Attributes.class "col tags d-flex justify-content-center" ]
            (tags
                |> List.map (\x -> badge state x)
            )
        ]
    , Html.hr [ Html.Attributes.style "margin-top" "0.3em" ] []
    , Html.div [ Html.Attributes.class "row documents" ]
        [ Html.div [ Html.Attributes.class "col" ]
            [ Html.div [ Html.Attributes.class "cards d-flex justify-content-around flex-wrap" ] (Views.Documents.cards state documents)
            ]
        ]
    ]



-- Private members


badge : Models.State -> String -> Html Msgs.Main.Msg
badge state tag =
    let
        tagsState =
            state.tagsState
                |> Maybe.withDefault Factories.tagsStateFactory

        badgeStyles =
            if Set.member tag tagsState.selected then
                "badge badge-success"

            else
                "badge badge-secondary"
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
