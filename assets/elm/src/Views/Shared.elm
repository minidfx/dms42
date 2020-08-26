module Views.Shared exposing (badge, card, flattenTags, getAndLoadTags, getTags, handleTags, pagination, posix2String, refreshDocumentTags, tagsInputs)

import Bootstrap.General.HAlign
import Bootstrap.Pagination
import Bootstrap.Pagination.Item
import Browser.Dom
import Dict
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


tagsInputs : Bool -> Html Msgs.Main.Msg
tagsInputs isDisabled =
    Html.Keyed.node "tags"
        []
        [ ( "tags_input"
          , Html.select
                [ Html.Attributes.id "tags"
                , Html.Attributes.disabled isDisabled
                , Html.Attributes.class "form-control"
                , Html.Attributes.multiple True
                , Html.Attributes.attribute "data-placeholder" "Insert your tags"
                , Html.Attributes.style "border-width" "0"
                ]
                []
          )
        ]


pagination : Maybe Browser.Dom.Viewport -> Int -> Int -> Int -> (Int -> String) -> Html Msgs.Main.Msg
pagination viewport total length offset urlFn =
    let
        maxItems =
            case viewport of
                Just x ->
                    Basics.min 50 <| Basics.floor <| x.viewport.width * 0.011

                Nothing ->
                    15

        activeIdx =
            (//) offset length

        pagesCount =
            (//) (total - 1) length

        localItems =
            if pagesCount > maxItems then
                let
                    halfMaxItems =
                        (//) maxItems 2

                    leftPart =
                        if activeIdx - halfMaxItems > 0 then
                            [ First urlFn, Space ]

                        else
                            []

                    rightPart =
                        if activeIdx + halfMaxItems < pagesCount then
                            [ Space, Last pagesCount urlFn ]

                        else
                            []

                    middlePart =
                        let
                            from =
                                Basics.min (pagesCount - maxItems) <| Basics.max 0 (activeIdx - halfMaxItems)

                            to =
                                Basics.max (0 + maxItems) <| Basics.min pagesCount (activeIdx + halfMaxItems)
                        in
                        List.range from to |> List.map (\x -> Numeric x urlFn)
                in
                List.concat [ leftPart, middlePart, rightPart ]

            else
                List.range 0 pagesCount |> List.map (\x -> Numeric x urlFn)

        items =
            localItems |> List.map (\x -> yieldPaginationItems x activeIdx)
    in
    Html.div
        []
        [ Bootstrap.Pagination.defaultConfig
            |> Bootstrap.Pagination.align Bootstrap.General.HAlign.centerXs
            |> Bootstrap.Pagination.ariaLabel "documents-pagination"
            |> Bootstrap.Pagination.items items
            |> Bootstrap.Pagination.view
        ]


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
handleTags state result thenLoad =
    let
        { route } =
            state

        tags =
            case result of
                Ok x ->
                    x

                Err _ ->
                    []

        newState =
            if thenLoad then
                { state | tagsResponse = Just tags, tagsLoaded = True }

            else
                { state | tagsResponse = Just tags, tagsLoaded = False }

        commands =
            if thenLoad then
                case route of
                    Models.Document id _ ->
                        let
                            documents =
                                state.documentsState
                                    |> Maybe.andThen (\x -> x.documents)
                                    |> Maybe.withDefault Dict.empty

                            documentTags =
                                Dict.get id documents
                                    |> Maybe.andThen (\x -> Just x.tags)
                                    |> Maybe.withDefault []
                        in
                        Ports.Gates.tags { jQueryPath = "#tags", documentId = Just id, tags = tags, documentTags = documentTags }

                    _ ->
                        Ports.Gates.tags { jQueryPath = "#tags", documentId = Nothing, tags = tags, documentTags = [] }

            else
                Cmd.none
    in
    ( newState
    , commands
    )


refreshDocumentTags : Models.State -> String -> ( Models.State, Cmd Msgs.Main.Msg )
refreshDocumentTags ({ documentsState, tagsResponse } as state) documentId =
    let
        tags =
            tagsResponse
                |> Maybe.withDefault []

        documents =
            documentsState
                |> Maybe.andThen (\x -> x.documents)
                |> Maybe.withDefault Dict.empty

        documentTags =
            Dict.get documentId documents
                |> Maybe.andThen (\x -> Just x.tags)
                |> Maybe.withDefault []
    in
    ( { state | tagsLoaded = True }
    , Ports.Gates.tags { jQueryPath = "#tags", documentId = Just <| documentId, tags = tags, documentTags = documentTags }
    )



-- Private members


type PaginationContentType
    = Numeric Int (Int -> String)
    | Space
    | First (Int -> String)
    | Last Int (Int -> String)


yieldPaginationItems : PaginationContentType -> Int -> Bootstrap.Pagination.Item.Item Msgs.Main.Msg
yieldPaginationItems item activeIndex =
    case item of
        Numeric x urlFn ->
            Bootstrap.Pagination.Item.item
                |> Bootstrap.Pagination.Item.active (x == activeIndex)
                |> Bootstrap.Pagination.Item.link
                    [ Html.Attributes.href <| urlFn x ]
                    (numericPaginationContent <| x + 1)

        Space ->
            Bootstrap.Pagination.Item.item
                |> Bootstrap.Pagination.Item.disabled True
                |> Bootstrap.Pagination.Item.link [] spacePaginationContent

        First urlFn ->
            Bootstrap.Pagination.Item.item
                |> Bootstrap.Pagination.Item.disabled False
                |> Bootstrap.Pagination.Item.link
                    [ Html.Attributes.href <| urlFn 0 ]
                    backwardPaginationContent

        Last x urlFn ->
            Bootstrap.Pagination.Item.item
                |> Bootstrap.Pagination.Item.disabled False
                |> Bootstrap.Pagination.Item.link
                    [ Html.Attributes.href <| urlFn x ]
                    forwardPaginationContent


numericPaginationContent : Int -> List (Html Msgs.Main.Msg)
numericPaginationContent index =
    [ Html.span []
        [ Html.text <| String.fromInt index ]
    ]


spacePaginationContent : List (Html Msgs.Main.Msg)
spacePaginationContent =
    [ Html.span []
        [ Html.text "..." ]
    ]


forwardPaginationContent : List (Html Msgs.Main.Msg)
forwardPaginationContent =
    [ Html.span
        [ Html.Attributes.class "fa fa-forward"
        , Html.Attributes.attribute "aria-hidden" "true"
        ]
        []
    , Html.span [ Html.Attributes.class "sr-only" ]
        [ Html.text "Next" ]
    ]


backwardPaginationContent : List (Html Msgs.Main.Msg)
backwardPaginationContent =
    [ Html.span
        [ Html.Attributes.class "fa fa-backward"
        , Html.Attributes.attribute "aria-hidden" "true"
        ]
        []
    , Html.span [ Html.Attributes.class "sr-only" ]
        [ Html.text "Previous" ]
    ]


tagsDecoder : Json.Decode.Decoder (List String)
tagsDecoder =
    Json.Decode.list Json.Decode.string


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
