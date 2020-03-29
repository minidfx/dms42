module Helpers exposing (..)

import Http
import Url



-- Public members


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
