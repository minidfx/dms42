module Helpers exposing
    ( basePath
    , fluentSelect
    , fluentUpdate
    , httpErrorToString
    , isSamePage
    , navTo
    , protocol2String
    )

import Browser
import Http
import Models
import String.Format
import Url exposing (Url)
import Url.Builder



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


basePath : Url -> String
basePath { protocol, host, port_ } =
    case port_ of
        Just x ->
            "{{ protocol }}://{{ host }}:{{ port }}"
                |> (String.Format.namedValue "protocol" <| protocol2String <| protocol)
                |> String.Format.namedValue "host" host
                |> (String.Format.namedValue "port" <| String.fromInt x)

        Nothing ->
            "{{ protocol }}://{{ host }}:{{ port }}"
                |> (String.Format.namedValue "protocol" <| protocol2String <| protocol)
                |> String.Format.namedValue "host" host


navTo : Models.State -> List String -> List Url.Builder.QueryParameter -> Browser.UrlRequest
navTo { url } path arguments =
    Browser.Internal <| Maybe.withDefault url <| Url.fromString <| Url.Builder.crossOrigin (basePath url) path arguments


isSamePage : Url.Url -> Url.Url -> Bool
isSamePage url url2 =
    url.host == url2.host && url.path == url2.path
