module Middlewares.Tags exposing (update)

import Helpers exposing (isSamePage)
import Models
import Msgs.Main exposing (MiddlewareContext(..))
import Ports.Gates


update : Msgs.Main.Msg -> Models.State -> MiddlewareContext
update msg ({ tagsLoaded, history } as state) =
    case msg of
        Msgs.Main.UrlChanged url ->
            let
                previousUrl =
                    List.head history

                localIsSamePage =
                    previousUrl
                        |> Maybe.andThen (\u -> Just <| isSamePage u url)
                        |> Maybe.withDefault True
            in
            -- INFO: Make sure to clear the previous DOM element loaded with the tags.
            case not localIsSamePage && tagsLoaded of
                True ->
                    Continue
                        ( { state | tagsLoaded = False }
                        , Cmd.batch [ Ports.Gates.unloadTags { jQueryPath = "#tags" } ]
                        )

                _ ->
                    Continue ( state, Cmd.none )

        _ ->
            Continue ( state, Cmd.none )
