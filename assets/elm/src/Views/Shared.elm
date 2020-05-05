module Views.Shared exposing (badge, card, flattenTags, getAndLoadTags, getTags, handleTags, pagination, posix2String, tagsinputs)

import Bootstrap.General.HAlign
import Bootstrap.Pagination
import Dict
import Factories
import Helpers
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Html.Keyed
import Http
import Json.Decode
import Models
import Msgs.Main
import Ports.Gates
import Set
import String.Format
import Time



-- Public members


posix2String : Time.Zone -> Time.Posix -> String
posix2String zone timestamp =
    "{{ day }} {{ month }} {{ year }}, {{ hour }}:{{ minute }}"
        |> (String.Format.namedValue "day" <| String.fromInt <| Time.toDay zone timestamp)
        |> (String.Format.namedValue "month" <| month2String <| Time.toMonth zone timestamp)
        |> (String.Format.namedValue "year" <| String.fromInt <| Time.toYear zone timestamp)
        |> (String.Format.namedValue "hour" <| String.padLeft 2 '0' <| String.fromInt <| Time.toHour zone timestamp)
        |> (String.Format.namedValue "minute" <| String.padLeft 2 '0' <| String.fromInt <| Time.toMinute zone timestamp)


card : Models.State -> Models.DocumentResponse -> Html Msgs.Main.Msg
card state { datetimes, id, tags, thumbnails } =
    let
        { key, url, userTimeZone } =
            state

        timeZone =
            userTimeZone |> Maybe.withDefault Time.utc

        { inserted_datetime, updated_datetime } =
            datetimes

        { countImages } =
            thumbnails
    in
    Html.div [ Html.Attributes.class "dms42-card" ]
        [ Html.div
            [ Html.Attributes.class "dms42-card-img d-flex align-items-center" ]
            [ Html.img
                [ Html.Attributes.src <| ("/documents/thumbnail/{{ }}" |> String.Format.value id)
                , Html.Events.onClick <| Msgs.Main.LinkClicked <| Helpers.navTo state [ "documents", id ] []
                ]
                []
            , Html.div [ Html.Attributes.class "dms42-card-count px-1 py-0 border rounded-left text-light bg-dark" ] [ Html.text <| String.fromInt countImages ]
            ]
        , Html.div [ Html.Attributes.class "dms42-card-body" ]
            [ Html.div [ Html.Attributes.class "dms42-card-datetime d-flex justify-content-center" ]
                [ Html.text <| posix2String timeZone inserted_datetime ]
            , flattenTags tags
            ]
        ]


badge : String -> Html Msgs.Main.Msg
badge tag =
    Html.span [ Html.Attributes.class "badge badge-info" ] [ Html.text tag ]


flattenTags : List String -> Html Msgs.Main.Msg
flattenTags tags =
    Html.div [ Html.Attributes.class "dms42-card-tags d-flex flex-wrap justify-content-center my-1" ] (List.map (\x -> badge x) tags)


tagsinputs : Bool -> Html Msgs.Main.Msg
tagsinputs isDisabled =
    Html.Keyed.node "tags"
        []
        [ ( "tags_input"
          , Html.select
                [ Html.Attributes.id "tags"
                , Html.Attributes.disabled isDisabled
                , Html.Attributes.class "form-control"
                , Html.Attributes.multiple True
                , Html.Attributes.attribute "data-placeholder" "Insert your tags"
                ]
                []
          )
        ]


pagination : Int -> Int -> Int -> (Int -> String) -> Html Msgs.Main.Msg
pagination total length offset urlFn =
    let
        countItems =
            List.range 0 ((//) (total - 1) length) |> List.map (\x -> String.fromInt x)

        items =
            countItems

        activeIdx =
            (//) offset length

        itemsList =
            { selectedMsg = \_ -> Msgs.Main.Nop
            , prevItem = Nothing
            , nextItem = Nothing
            , activeIdx = activeIdx
            , data = items
            , itemFn = itemFn
            , urlFn = \x y -> baseUrlFn x y urlFn
            }
    in
    Bootstrap.Pagination.defaultConfig
        |> Bootstrap.Pagination.align Bootstrap.General.HAlign.centerXs
        |> Bootstrap.Pagination.ariaLabel "documents-pagination"
        |> Bootstrap.Pagination.itemsList itemsList
        |> Bootstrap.Pagination.view


getAndLoadTags : Cmd Msgs.Main.Msg
getAndLoadTags =
    Http.get
        { url = "/api/tags"
        , expect = Http.expectJson Msgs.Main.GotAndLoadTags tagsDecoder
        }


getTags : Cmd Msgs.Main.Msg
getTags =
    Http.get
        { url = "/api/tags"
        , expect = Http.expectJson Msgs.Main.GotTags tagsDecoder
        }


handleTags : Models.State -> Result Http.Error (List String) -> Bool -> ( Models.State, Cmd Msgs.Main.Msg )
handleTags state result loadThem =
    let
        { route } =
            state

        tags =
            case result of
                Ok x ->
                    x

                Err _ ->
                    []

        tagsState =
            state.tagsState |> Maybe.withDefault Factories.tagsStateFactory

        newStateWithTags =
            { state | tagsState = Just { tagsState | tags = Set.fromList tags } }

        documentId =
            case route of
                Models.Document id _ ->
                    Just id

                _ ->
                    Nothing

        documents =
            state.documentsState
                |> Maybe.withDefault Factories.documentsStateFactory
                |> Helpers.fluentSelect (\x -> x.documents)
                |> Maybe.withDefault Dict.empty

        -- FIXME: Don't like this syntax, too many nesting with the case statement.
        documentTags =
            case documentId of
                Just id ->
                    case Dict.get id <| documents of
                        Just x ->
                            x.tags

                        Nothing ->
                            []

                Nothing ->
                    []

        commands =
            if loadThem then
                Ports.Gates.tags { jQueryPath = "#tags", documentId = documentId, tags = tags, documentTags = documentTags }

            else
                Cmd.none
    in
    ( { newStateWithTags | tagsResponse = Just tags }
    , commands
    )



-- Private members


tagsDecoder : Json.Decode.Decoder (List String)
tagsDecoder =
    Json.Decode.list Json.Decode.string


baseUrlFn : Int -> String -> (Int -> String) -> String
baseUrlFn idx text baseCallback =
    if String.fromInt idx == text then
        baseCallback idx

    else
        "/"


itemFn : Int -> String -> Bootstrap.Pagination.ListItem msg
itemFn idx text =
    if String.fromInt idx == text then
        Bootstrap.Pagination.ListItem [] [ Html.text <| String.fromInt <| (+) idx 1 ]

    else
        Bootstrap.Pagination.ListItem [] [ Html.text text ]


month2String : Time.Month -> String
month2String month =
    case month of
        Time.Jan ->
            "January"

        Time.Feb ->
            "February"

        Time.Mar ->
            "Mars"

        Time.Apr ->
            "April"

        Time.May ->
            "May"

        Time.Jun ->
            "June"

        Time.Jul ->
            "July"

        Time.Aug ->
            "August"

        Time.Sep ->
            "September"

        Time.Oct ->
            "October"

        Time.Nov ->
            "November"

        Time.Dec ->
            "December"
