module Views.Shared exposing (badge, card, flattenTags, posix2String)

import Bootstrap.Card
import Bootstrap.Card.Block
import Browser
import Helpers
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Models
import String.Format
import Time
import Url
import Url.Builder



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
card { key, url, userTimeZone } { datetimes, id, tags } =
    let
        timeZone =
            userTimeZone |> Maybe.withDefault Time.utc

        { inserted_datetime, updated_datetime } =
            datetimes

        { protocol, host, port_ } =
            url

        basePath =
            case port_ of
                Just x ->
                    "{{ protocol }}://{{ host }}:{{ port }}"
                        |> (String.Format.namedValue "protocol" <| Helpers.protocol2String <| protocol)
                        |> String.Format.namedValue "host" host
                        |> (String.Format.namedValue "port" <| String.fromInt x)

                Nothing ->
                    "{{ protocol }}://{{ host }}:{{ port }}"
                        |> (String.Format.namedValue "protocol" <| Helpers.protocol2String <| protocol)
                        |> String.Format.namedValue "host" host
    in
    Bootstrap.Card.config [ Bootstrap.Card.light, Bootstrap.Card.attrs [ Html.Attributes.style "max-width" "155px" ] ]
        |> Bootstrap.Card.imgTop
            [ Html.Attributes.src <| ("/documents/thumbnail/{{ }}" |> String.Format.value id)
            , Html.Events.onClick <| Models.LinkClicked <| Browser.Internal <| Maybe.withDefault url <| Url.fromString <| Url.Builder.crossOrigin basePath [ "documents", id ] []
            ]
            []
        |> Bootstrap.Card.block []
            [ Bootstrap.Card.Block.text [] [ Html.text <| posix2String timeZone inserted_datetime ]
            , Bootstrap.Card.Block.text [] [ flattenTags tags ]
            ]
        |> Bootstrap.Card.view


badge : String -> Html Models.Msg
badge tag =
    Html.span [ Html.Attributes.class "badge badge-info" ] [ Html.text tag ]


flattenTags : List String -> Html Models.Msg
flattenTags tags =
    Html.div [ Html.Attributes.class "badges d-flex flex-wrap" ] (List.map (\x -> badge x) tags)



-- Private members


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
