module Helpers exposing (fluentSelect, fluentUpdate, httpErrorToString, posix2String, protocol2String)

import Http
import String.Format
import Time
import Url



-- Public members


posix2String : Time.Zone -> Time.Posix -> String
posix2String zone timestamp =
    "{{ day }} {{ month }} {{ year }}"
        |> (String.Format.namedValue "day" <| String.fromInt <| Time.toDay zone timestamp)
        |> (String.Format.namedValue "month" <| month2String <| Time.toMonth zone timestamp)
        |> (String.Format.namedValue "year" <| String.fromInt <| Time.toYear zone timestamp)


fluentUpdate : (a -> a) -> a -> a
fluentUpdate func a =
    func a


fluentSelect : (a -> b) -> a -> b
fluentSelect func object =
    func object


httpErrorToString : Http.Error -> String
httpErrorToString error =
    case error of
        Http.BadUrl x ->
            x

        Http.Timeout ->
            "timeout"

        Http.NetworkError ->
            "NetworkError"

        Http.BadStatus x ->
            String.fromInt x

        Http.BadBody x ->
            x


protocol2String : Url.Protocol -> String
protocol2String protocol =
    case protocol of
        Url.Http ->
            "http"

        Url.Https ->
            "https"



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
