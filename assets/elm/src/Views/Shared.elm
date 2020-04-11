module Views.Shared exposing (badge, card, flattenTags, pagination, posix2String, tagsinputs)

import Bootstrap.Card
import Bootstrap.Card.Block
import Bootstrap.General.HAlign
import Bootstrap.Pagination
import Helpers
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Html.Keyed
import Models
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


card : Models.State -> Models.DocumentResponse -> Html Models.Msg
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
                , Html.Events.onClick <| Models.LinkClicked <| Helpers.navTo state [ "documents", id ] []
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


badge : String -> Html Models.Msg
badge tag =
    Html.span [ Html.Attributes.class "badge badge-info" ] [ Html.text tag ]


flattenTags : List String -> Html Models.Msg
flattenTags tags =
    Html.div [ Html.Attributes.class "dms42-card-tags d-flex flex-wrap justify-content-center my-1" ] (List.map (\x -> badge x) tags)


tagsinputs : List String -> Bool -> Html Models.Msg
tagsinputs tags isDisabled =
    Html.Keyed.node "tags"
        []
        [ ( "tags_input"
          , Html.input
                [ Html.Attributes.type_ "text"
                , Html.Attributes.class "form-control typeahead"
                , Html.Attributes.id "tags"
                , Html.Attributes.attribute "data-role" "tagsinput"
                , Html.Attributes.value <| String.join "," <| tags
                , Html.Attributes.disabled isDisabled
                ]
                []
          )
        ]


pagination : Int -> Int -> Maybe Int -> (Int -> String) -> Html Models.Msg
pagination total length offset urlFn =
    let
        localOffset =
            Maybe.withDefault 0 offset

        countItems =
            List.range 0 ((//) (total - 1) length) |> List.map (\x -> String.fromInt x)

        items =
            countItems

        activeIdx =
            (//) localOffset length

        itemsList =
            { selectedMsg = \_ -> Models.Nop
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



-- Private members


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
