module Main exposing (init, main, subscriptions, update, view)

import Bootstrap.Modal
import Bootstrap.Navbar
import Bootstrap.Spinner
import Bootstrap.Text
import Browser
import Browser.Dom
import Browser.Navigation as Nav
import Factories
import Helpers
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events
import Middlewares.Alerts
import Middlewares.CloseModal
import Middlewares.Fallback
import Middlewares.Global
import Middlewares.History
import Middlewares.LinkClicked
import Middlewares.Router exposing (routes)
import Middlewares.UnloadSelect2Control
import Middlewares.Updates
import Models
import Msgs.AddDocument
import Msgs.Alerts
import Msgs.Document
import Msgs.Documents
import Msgs.Main exposing (MiddlewareContext(..))
import Ports.Gates
import ScrollTo
import String.Format
import Task
import Time
import Url exposing (Url)
import Url.Parser exposing (..)
import Views.AddDocuments
import Views.Document
import Views.Documents
import Views.Home
import Views.Settings
import Views.Tags



-- MAIN


main : Program () Models.State Msgs.Main.Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = Msgs.Main.UrlChanged
        , onUrlRequest = Msgs.Main.LinkClicked
        }



-- MODEL


init : () -> Url.Url -> Nav.Key -> ( Models.State, Cmd Msgs.Main.Msg )
init flags url key =
    let
        defaultActions =
            [ Task.perform Msgs.Main.GotUserTimeZone Time.here
            , Task.perform Msgs.Main.GotViewPort Browser.Dom.getViewport
            ]

        route =
            Url.Parser.parse routes url |> Maybe.withDefault (Models.Home Nothing)

        ( navBarState, navBarCmd ) =
            Bootstrap.Navbar.initialState Msgs.Main.NavbarMsg

        initialState =
            Factories.stateFactory key url route navBarState

        ( state, commands ) =
            case route of
                Models.AddDocuments ->
                    Views.AddDocuments.init flags key initialState Msgs.AddDocument.Home

                Models.Documents offset ->
                    Views.Documents.init flags key initialState Msgs.Documents.Home offset

                Models.Document documentId _ ->
                    Views.Document.init flags key initialState Msgs.Document.Home (Just documentId)

                Models.Settings ->
                    Views.Settings.init initialState

                Models.Home query ->
                    Views.Home.init initialState query

                Models.Tags ->
                    Views.Tags.init flags key initialState

        newCommands =
            Cmd.batch <| defaultActions ++ [ navBarCmd, commands ]
    in
    ( state, newCommands )



-- UPDATE


middlewares : List (Msgs.Main.Msg -> Models.State -> MiddlewareContext)
middlewares =
    -- WARN: The middleware order is IMPORTANT.
    [ Middlewares.Global.update
    , Middlewares.CloseModal.update
    , Middlewares.UnloadSelect2Control.update
    , Middlewares.LinkClicked.update
    , Middlewares.Router.update
    , Middlewares.Alerts.update
    , Middlewares.Updates.update
    , Middlewares.History.update
    , Middlewares.Fallback.update
    ]


middlewareReducer :
    Msgs.Main.Msg
    -> (Msgs.Main.Msg -> Models.State -> MiddlewareContext)
    -> MiddlewareContext
    -> MiddlewareContext
middlewareReducer msg func context =
    case context of
        Continue ( state, msgs ) ->
            case func msg state of
                Continue ( newState, newMsgs ) ->
                    Continue ( newState, Cmd.batch [ msgs, newMsgs ] )

                Break ( newState, newMsgs ) ->
                    Break ( newState, Cmd.batch [ msgs, newMsgs ] )

        Break x ->
            Break x


update : Msgs.Main.Msg -> Models.State -> ( Models.State, Cmd Msgs.Main.Msg )
update msg state =
    let
        context =
            List.foldl (\x acc -> middlewareReducer msg x acc)
                (Continue ( state, Cmd.none ))
                middlewares
    in
    case context of
        Continue x ->
            x

        Break x ->
            x



-- SUBSCRIPTIONS


subscriptions : Models.State -> Sub Msgs.Main.Msg
subscriptions { modalVisibility, scrollTo, navBarState } =
    let
        baseCommands =
            [ Ports.Gates.uploadCompleted (always <| Msgs.Main.AddDocumentMsg Msgs.AddDocument.UploadCompleted)
            , Ports.Gates.addTags <| Msgs.Main.DocumentMsg << Msgs.Document.AddTags
            , Ports.Gates.removeTags <| Msgs.Main.DocumentMsg << Msgs.Document.RemoveTags
            , Sub.map Msgs.Main.ScrollToMsg <| ScrollTo.subscriptions scrollTo
            , Bootstrap.Navbar.subscriptions navBarState Msgs.Main.NavbarMsg
            ]

        commands =
            case modalVisibility of
                Just modal ->
                    baseCommands ++ [ Bootstrap.Modal.subscriptions modal.visibility Msgs.Main.AnimatedModal ]

                Nothing ->
                    baseCommands
    in
    Sub.batch commands



-- VIEW


navbar : Models.State -> Html Msgs.Main.Msg
navbar ({ navBarState, isLoading } as state) =
    Bootstrap.Navbar.config Msgs.Main.NavbarMsg
        |> Bootstrap.Navbar.withAnimation
        |> Bootstrap.Navbar.dark
        |> Bootstrap.Navbar.brand
            [ Html.Attributes.href "/"
            , Html.Attributes.class "d-flex align-items-center"
            ]
            [ Html.img
                [ Html.Attributes.title "DMS42"
                , Html.Attributes.src "/images/brand.png"
                , Html.Attributes.class "mr-2 p-1 rounded"
                ]
                []
            , Html.text "DMS42"
            ]
        |> Bootstrap.Navbar.items
            [ yieldItem state "Home" <| Nothing
            , yieldItem state "Tags" <| Just "/tags"
            , yieldItem state "Documents" <| Just "/documents"
            , yieldItem state "Settings" <| Just "/settings"
            ]
        |> Helpers.fluentUpdate
            (\x ->
                if isLoading then
                    Bootstrap.Navbar.customItems
                        [ Bootstrap.Navbar.customItem <|
                            Html.span [ Html.Attributes.class "mt-1" ]
                                [ Bootstrap.Spinner.spinner
                                    [ Bootstrap.Spinner.small
                                    , Bootstrap.Spinner.color Bootstrap.Text.primary
                                    ]
                                    [ Bootstrap.Spinner.srMessage "Loading ..." ]
                                ]
                        ]
                        x

                else
                    x
            )
        |> Bootstrap.Navbar.view navBarState


yieldItem : Models.State -> String -> Maybe String -> Bootstrap.Navbar.Item Msgs.Main.Msg
yieldItem { url } name startsWith =
    let
        { path } =
            url
    in
    case startsWith of
        Nothing ->
            if path == "/" then
                Bootstrap.Navbar.itemLinkActive [ Html.Attributes.href "/" ] [ Html.text name ]

            else
                Bootstrap.Navbar.itemLink [ Html.Attributes.href "/" ] [ Html.text name ]

        Just x ->
            if String.startsWith x path then
                Bootstrap.Navbar.itemLinkActive [ Html.Attributes.href x ] [ Html.text name ]

            else
                Bootstrap.Navbar.itemLink [ Html.Attributes.href x ] [ Html.text name ]


alertNode : Models.Alert -> Int -> Html Msgs.Main.Msg
alertNode { kind, id, message } topPosition =
    let
        alertClass =
            case kind of
                Models.Danger ->
                    "alert-danger"

                Models.Warning ->
                    "alert-warning"

                Models.Information ->
                    "alert-info"
    in
    Html.div
        [ Html.Attributes.class "dms42-alert d-flex flex-row-reverse w-30"
        , Html.Attributes.style "top" <| (String.Format.value <| String.fromInt <| topPosition) <| "{{ }}em"
        , Html.Attributes.style "right" "1em"
        , Html.Attributes.style "z-index" "1080"
        ]
        [ Html.div
            [ Html.Attributes.class <| "alert alert-dismissible fade show " ++ alertClass ]
            [ Html.text message
            , Html.button
                [ Html.Attributes.type_ "button"
                , Html.Attributes.class "close"
                , Html.Attributes.attribute "index" <| String.fromInt <| id
                , Html.Events.onClick <| (Msgs.Main.AlertMsg << Msgs.Alerts.Close) <| id
                ]
                [ Html.span
                    [ Html.Attributes.attribute "aria-label" "true" ]
                    [ Html.text <| String.fromChar <| Char.fromCode 215 ]
                ]
            ]
        ]


alertNodes : Models.State -> List (Html Msgs.Main.Msg)
alertNodes { alerts } =
    let
        topPosition index =
            index * 4 + 1
    in
    alerts |> List.indexedMap (\i x -> alertNode x <| topPosition i)


mainView : Models.State -> List (Html Msgs.Main.Msg)
mainView state =
    let
        content =
            case state.route of
                Models.Documents offset ->
                    Views.Documents.view state offset

                Models.Settings ->
                    Views.Settings.view state

                Models.AddDocuments ->
                    Views.AddDocuments.view state

                Models.Home _ ->
                    Views.Home.view state

                Models.Document id offset ->
                    Views.Document.view state id offset

                Models.Tags ->
                    Views.Tags.view state

        mainContent =
            [ Html.div [] <| alertNodes state
            , Html.div [] content
            ]
    in
    [ navbar state
    , Html.main_
        [ Html.Attributes.class "container-fluid"
        , Html.Attributes.attribute "role" "main"
        ]
        [ Html.div [ Html.Attributes.class "pt-5" ] mainContent ]
    ]


view : Models.State -> Browser.Document Msgs.Main.Msg
view state =
    { title = "DMS42"
    , body = mainView state
    }
