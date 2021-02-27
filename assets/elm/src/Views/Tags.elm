module Views.Tags exposing (init, update, view)

-- Public members

import Bootstrap.Form.Input
import Browser.Dom
import Browser.Navigation as Nav
import Factories
import Helpers
import Html exposing (Html)
import Html.Attributes
import Html.Events exposing (keyCode)
import Http
import Json.Decode
import Json.Encode
import Models exposing (AlertKind(..))
import Msgs.Main
import Msgs.Tags
import Set
import Simple.Fuzzy
import String.Format
import Task
import Views.Alerts
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
                        |> Helpers.fluentSelect .selected
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
                    state.tagsState |> Maybe.withDefault Factories.tagsStateFactory

                newState =
                    { state | tagsState = Just { tagsState | documents = Just documents }, isLoading = False }
            in
            ( newState, Cmd.none )

        Msgs.Tags.CleanResult ->
            let
                localTagsState =
                    state.tagsState
                        |> Maybe.withDefault Factories.tagsStateFactory
                        |> Helpers.fluentSelect (\x -> { x | documents = Nothing })
            in
            ( { state | tagsState = Just localTagsState, isLoading = False }, Cmd.none )

        Msgs.Tags.UserTypeFilter filter ->
            let
                tagsState =
                    state.tagsState |> Maybe.withDefault Factories.tagsStateFactory
            in
            ( { state | tagsState = Just { tagsState | filter = Just filter } }, Cmd.none )

        Msgs.Tags.Clear ->
            let
                tagsState =
                    state.tagsState |> Maybe.withDefault Factories.tagsStateFactory
            in
            ( { state | tagsState = Just { tagsState | filter = Nothing } }, Cmd.none )

        Msgs.Tags.OnInputEditTag tag ->
            let
                -- local function to safely update the tag request
                safeUpdateTagRequest : Models.TagsState -> Models.TagsState
                safeUpdateTagRequest ({ updateTagRequest } as request) =
                    let
                        localUpdateTagRequest =
                            updateTagRequest
                                |> Maybe.withDefault (Factories.updateTagRequestFactory tag)
                                |> Helpers.fluentUpdate (\y -> { y | newTag = tag })
                    in
                    { request | updateTagRequest = Just localUpdateTagRequest }

                localTagsState =
                    state.tagsState
                        |> Maybe.withDefault Factories.tagsStateFactory
                        |> Helpers.fluentSelect safeUpdateTagRequest
            in
            ( { state | tagsState = Just localTagsState }, Cmd.none )

        Msgs.Tags.EditTag tag ->
            let
                localTagsState =
                    state.tagsState
                        |> Maybe.withDefault Factories.tagsStateFactory
                        |> Helpers.fluentSelect (\x -> { x | updateTagRequest = Just <| Factories.updateTagRequestFactory tag })

                localUpdateTagRequest =
                    localTagsState
                        |> Helpers.fluentSelect .updateTagRequest
                        |> Maybe.withDefault (Factories.updateTagRequestFactory tag)
            in
            ( { state | tagsState = Just localTagsState }
            , Cmd.batch [ Task.attempt (\_ -> Msgs.Main.Nop) (Browser.Dom.focus <| inputTagFieldId <| localUpdateTagRequest) ]
            )

        Msgs.Tags.UpdateTag { oldTag, newTag } ->
            if oldTag == newTag then
                let
                    localTagsState =
                        state.tagsState
                            |> Maybe.withDefault Factories.tagsStateFactory
                            |> Helpers.fluentSelect (\x -> { x | updateTagRequest = Nothing })
                in
                ( { state | tagsState = Just localTagsState }, Cmd.none )

            else if String.length newTag < 3 then
                ( state
                , Cmd.batch
                    [ Views.Alerts.publish <|
                        { kind = Models.Danger
                        , message = "The new text should have at least 3 characters."
                        , timeout = Just 5
                        }
                    ]
                )

            else
                ( { state | isLoading = True }
                , Http.request
                    { method = "PUT"
                    , headers = []
                    , url = "/api/tags"
                    , body = Http.jsonBody <| Json.Encode.object <| [ ( "oldTag", Json.Encode.string oldTag ), ( "newTag", Json.Encode.string newTag ) ]
                    , expect = Http.expectJson (Msgs.Main.TagsMsg << Msgs.Tags.DidUpdateTag) updateTagResponseDecoder
                    , timeout = Nothing
                    , tracker = Nothing
                    }
                )

        Msgs.Tags.OnKeyPressEditTag key ->
            if key == 13 then
                let
                    localUpdateTagRequest =
                        state.tagsState
                            |> Maybe.withDefault Factories.tagsStateFactory
                            |> Helpers.fluentSelect .updateTagRequest
                in
                case localUpdateTagRequest of
                    Just x ->
                        ( state
                        , Cmd.batch
                            [ x
                                |> Msgs.Tags.UpdateTag
                                |> Msgs.Main.TagsMsg
                                |> Task.succeed
                                |> Task.perform identity
                            ]
                        )

                    Nothing ->
                        ( state, Cmd.none )

            else
                ( state, Cmd.none )

        Msgs.Tags.DidUpdateTag result ->
            case result of
                Ok _ ->
                    ( state
                    , Cmd.batch
                        [ Views.Shared.getTags
                        , Msgs.Tags.DidRefreshTags
                            |> Msgs.Main.TagsMsg
                            |> Task.succeed
                            |> Task.perform identity
                        , Views.Alerts.publish
                            { kind = Models.Information
                            , message = "Successfully updated the tag."
                            , timeout = Just 5
                            }
                        ]
                    )

                Err x ->
                    ( { state | isLoading = False }
                    , Cmd.batch
                        [ Views.Alerts.publish <|
                            { kind = Models.Danger
                            , message = Helpers.httpErrorToString x
                            , timeout = Nothing
                            }
                        ]
                    )

        Msgs.Tags.DidRefreshTags ->
            let
                localTagsState =
                    state.tagsState
                        |> Maybe.withDefault Factories.tagsStateFactory
                        |> Helpers.fluentSelect (\x -> { x | updateTagRequest = Nothing })
            in
            ( { state | isLoading = False, tagsState = Just localTagsState }, Cmd.none )

        Msgs.Tags.Nop ->
            ( state, Cmd.none )


view : Models.State -> List (Html Msgs.Main.Msg)
view ({ tagsState, tagsResponse, isLoading } as state) =
    [ Html.div [ Html.Attributes.class "row" ]
        [ Html.div [ Html.Attributes.class "col-6 col-xs-6 col-sm-5 col-md-4 col-lg-3 col-xl-2 col-xxl-1" ] <| filterTags state
        , Html.div [ Html.Attributes.class "col cards d-flex flex-wrap align-content-start" ] <| filterDocuments state
        ]
    ]



-- Private members


filterDocuments : Models.State -> List (Html Msgs.Main.Msg)
filterDocuments ({ tagsState } as state) =
    let
        localTagsState =
            tagsState
                |> Maybe.withDefault Factories.tagsStateFactory

        documents =
            localTagsState.documents |> Maybe.withDefault []
    in
    Views.Documents.cards state documents


filterTags : Models.State -> List (Html Msgs.Main.Msg)
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

        tagNodes =
            tags
                |> List.sort
                |> List.map (\x -> badge state x)
    in
    [ Html.div []
        [ Html.div
            [ Html.Attributes.class "input-group mb-3" ]
            [ Html.input
                [ Html.Attributes.type_ "text"
                , Html.Attributes.class "form-control"
                , Html.Attributes.id "tags-query"
                , Html.Attributes.placeholder "Tags"
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
                [ Html.span
                    [ Html.Attributes.class "input-group-text"
                    , Html.Attributes.attribute "aria-describedby" "filterTags"
                    ]
                    [ Html.i
                        [ Html.Attributes.class "fas fa-filter"
                        , Html.Attributes.id "filterTags"
                        ]
                        []
                    ]
                ]
            ]
        , Html.div [ Html.Attributes.class "tags" ] tagNodes
        ]
    ]


badge : Models.State -> String -> Html Msgs.Main.Msg
badge ({ isLoading, tagsState } as state) tag =
    let
        updateTagRequest =
            tagsState
                |> Maybe.withDefault Factories.tagsStateFactory
                |> Helpers.fluentSelect .updateTagRequest
                |> Maybe.map
                    (\({ oldTag } as request) ->
                        if oldTag == tag then
                            Just request

                        else
                            Nothing
                    )
                |> Maybe.andThen (\x -> x)
    in
    Html.div [ Html.Attributes.class "row" ] <|
        case updateTagRequest of
            Just x ->
                badgeEdit state x

            Nothing ->
                badgeReadOnly state tag


badgeEdit : Models.State -> Models.UpdateTagRequest -> List (Html Msgs.Main.Msg)
badgeEdit { isLoading } updateTagRequest =
    [ Html.div
        [ Html.Attributes.class "col d-flex align-items-center" ]
        [ Bootstrap.Form.Input.text
            [ Bootstrap.Form.Input.small
            , Bootstrap.Form.Input.value <| Helpers.fluentSelect .newTag <| updateTagRequest
            , Bootstrap.Form.Input.onInput <| (Msgs.Main.TagsMsg << Msgs.Tags.OnInputEditTag)
            , Bootstrap.Form.Input.id <| inputTagFieldId <| updateTagRequest
            , Bootstrap.Form.Input.attrs [ onKeyDown <| Msgs.Main.TagsMsg << Msgs.Tags.OnKeyPressEditTag ]
            ]
        ]
    , Html.div
        [ Html.Attributes.class "col col-1 px-0 d-flex align-items-center" ]
        [ Html.button
            [ Html.Events.onClick <| (Msgs.Main.TagsMsg << Msgs.Tags.UpdateTag) <| updateTagRequest
            , Html.Attributes.disabled isLoading
            , Html.Attributes.type_ "button"
            , Html.Attributes.class "btn btn-link flex-fill px-0"
            ]
            [ Html.i
                [ Html.Attributes.class "fas fa-check"
                ]
                []
            ]
        ]
    ]


badgeReadOnly : Models.State -> String -> List (Html Msgs.Main.Msg)
badgeReadOnly { tagsState, isLoading } tag =
    let
        localTagsState =
            tagsState
                |> Maybe.withDefault Factories.tagsStateFactory

        isDisabled =
            localTagsState
                |> Helpers.fluentSelect .updateTagRequest
                |> Maybe.andThen (\{ oldTag } -> Just oldTag)
                |> Helpers.fluentSelect
                    (\x ->
                        case x of
                            Just _ ->
                                True

                            Nothing ->
                                isLoading
                    )

        badgeStyles =
            if isDisabled then
                "badge user-select-none"

            else if Set.member tag localTagsState.selected then
                "badge badge-success badge-pointer user-select-none"

            else
                "badge badge-secondary badge-pointer user-select-none"

        badgeAttributes =
            if isDisabled then
                [ Html.Attributes.class badgeStyles
                , Html.Attributes.title tag
                ]

            else
                [ Html.Attributes.class badgeStyles
                , Html.Events.onClick <| (Msgs.Main.TagsMsg << Msgs.Tags.ToggleTag) <| tag
                , Html.Attributes.title tag
                ]
    in
    [ Html.div
        [ Html.Attributes.class "col d-flex align-items-center" ]
        [ Html.span
            badgeAttributes
            [ Html.text <| truncateTag <| tag ]
        ]
    , Html.div
        [ Html.Attributes.class "col col-1 px-0 d-flex align-items-center" ]
        [ Html.button
            [ Html.Events.onClick <| (Msgs.Main.TagsMsg << Msgs.Tags.EditTag) <| tag
            , Html.Attributes.type_ "button"
            , Html.Attributes.class "btn btn-link flex-fill px-0"
            , Html.Attributes.disabled isDisabled
            ]
            [ Html.i
                [ Html.Attributes.class "fas fa-pen"
                ]
                []
            ]
        ]
    ]


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


updateTagResponseDecoder : Json.Decode.Decoder Models.UpdateTagResponse
updateTagResponseDecoder =
    Json.Decode.map Models.UpdateTagResponse
        (Json.Decode.field "newTag" Json.Decode.string)


onKeyDown : (Int -> msg) -> Html.Attribute msg
onKeyDown tagger =
    Html.Events.on "keydown" (Json.Decode.map tagger keyCode)


inputTagFieldId : Models.UpdateTagRequest -> String
inputTagFieldId { oldTag } =
    "tag-{{ }}" |> String.Format.value oldTag


truncateTag : String -> String
truncateTag text =
    if String.length text > 40 then
        "{{ }} ..." |> String.Format.value (String.slice 0 36 text)

    else
        text
