module Main exposing (init, main, subscriptions, update, view)

import Bootstrap.Modal
import Browser
import Browser.Navigation as Nav
import Debounce
import Factories
import Helpers
import Html exposing (..)
import Html.Attributes exposing (..)
import Models exposing (Msg(..))
import Ports.Gates
import Ports.Models
import ScrollTo
import Task
import Time
import Url exposing (Url)
import Url.Builder
import Url.Parser exposing (..)
import Url.Parser.Query
import Views.AddDocuments
import Views.Document
import Views.Documents
import Views.Home
import Views.Settings



-- MAIN


main : Program () Models.State Models.Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = Models.UrlChanged
        , onUrlRequest = Models.LinkClicked
        }



-- MODEL


routes : Url.Parser.Parser (Models.Route -> a) a
routes =
    Url.Parser.oneOf
        [ Url.Parser.map Models.Documents (Url.Parser.s "documents" <?> Url.Parser.Query.int "offset")
        , Url.Parser.map Models.AddDocuments (Url.Parser.s "documents" </> Url.Parser.s "add")
        , Url.Parser.map Models.Document (Url.Parser.s "documents" </> Url.Parser.string <?> Url.Parser.Query.int "offset")
        , Url.Parser.map Models.Settings (Url.Parser.s "settings")
        , Url.Parser.map Models.Home (Url.Parser.top <?> Url.Parser.Query.string "query")
        ]


init : () -> Url.Url -> Nav.Key -> ( Models.State, Cmd Models.Msg )
init flags url key =
    let
        defaultActions =
            Task.perform Models.GetUserTimeZone Time.here

        route =
            Url.Parser.parse routes url |> Maybe.withDefault (Models.Home Nothing)

        initialState =
            Factories.stateFactory key url route

        ( state, commands ) =
            case route of
                Models.AddDocuments ->
                    Views.AddDocuments.init flags key initialState

                Models.Documents offset ->
                    Views.Documents.init flags key initialState offset

                Models.Document id _ ->
                    Views.Document.init flags key initialState id

                Models.Settings ->
                    Views.Settings.update initialState

                Models.Home query ->
                    Views.Home.init initialState query

        newCommands =
            Cmd.batch [ defaultActions, commands ]
    in
    ( state, newCommands )



-- UPDATE


debounceConfig : (Debounce.Msg -> Models.Msg) -> Debounce.Config Models.Msg
debounceConfig debounceMsg =
    { strategy = Debounce.later 500
    , transform = debounceMsg
    }


update : Models.Msg -> Models.State -> ( Models.State, Cmd Models.Msg )
update msg state =
    case msg of
        Models.GotDocuments documentsResult ->
            Views.Documents.handleDocuments state documentsResult

        Models.LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( state, Nav.pushUrl state.key (Url.toString url) )

                Browser.External href ->
                    ( state, Nav.load href )

        Models.StartUpload ->
            ( { state | isUploading = True }
            , Cmd.batch [ Views.AddDocuments.startUpload ]
            )

        Models.UploadCompleted ->
            ( { state | isUploading = False }
            , Cmd.none
            )

        Models.UrlChanged url ->
            let
                route =
                    Url.Parser.parse routes url |> Maybe.withDefault (Models.Home Nothing)

                newState =
                    { state | url = url, route = route, error = Nothing }
            in
            case route of
                Models.AddDocuments ->
                    Views.AddDocuments.update newState

                Models.Documents offset ->
                    Views.Documents.update newState offset

                Models.Document id _ ->
                    Views.Document.update newState id

                Models.Settings ->
                    Views.Settings.update newState

                Models.Home query ->
                    Views.Home.update newState query

        Models.GetUserTimeZone zone ->
            ( { state | userTimeZone = Just zone }
            , Cmd.none
            )

        Models.AddTags { documentId, tags } ->
            ( state, Views.Document.addTags documentId tags )

        Models.RemoveTags { documentId, tags } ->
            ( state, Views.Document.removeTags documentId tags )

        Models.DidRemoveTags _ ->
            ( state, Cmd.none )

        Models.DidAddTags _ ->
            ( state, Cmd.none )

        Models.CloseModal ->
            ( { state | modalVisibility = Bootstrap.Modal.hidden }, Cmd.none )

        Models.ShowModal ->
            ( { state | modalVisibility = Bootstrap.Modal.shown }, Cmd.none )

        Models.AnimatedModal visibility ->
            ( { state | modalVisibility = visibility }, Cmd.none )

        Models.DeleteDocument documentId ->
            ( state, Views.Document.deleteDocument documentId )

        Models.DidDeleteDocument result ->
            Views.Document.didDeleteDocument state result

        Models.UserTypeSearch query ->
            let
                searchState =
                    Maybe.withDefault Factories.searchStateFactory <| state.searchState

                ( newDebouncer, cmd ) =
                    Debounce.push
                        (debounceConfig Models.ThrottleSearchDocuments)
                        query
                        searchState.debouncer
            in
            ( { state | searchState = Just { searchState | query = Just query, debouncer = newDebouncer } }
            , cmd
            )

        Models.ThrottleSearchDocuments msg_ ->
            let
                searchState =
                    Maybe.withDefault Factories.searchStateFactory <| state.searchState

                ( newDebouncer, cmd ) =
                    Debounce.update
                        (debounceConfig Models.ThrottleSearchDocuments)
                        (Debounce.takeLast (\x -> Task.perform Models.LinkClicked (Task.succeed <| Helpers.navTo state [] [ Url.Builder.string "query" x ])))
                        msg_
                        searchState.debouncer
            in
            ( { state | searchState = Just { searchState | debouncer = newDebouncer } }, cmd )

        Models.GotSearchResult result ->
            Views.Home.handleSearchResult state result

        Models.GotDocument result ->
            Views.Document.handleDocument state result

        Models.RunOcr document ->
            ( state, Views.Document.runOcr document )

        Models.RunUpdateThumbnails document ->
            ( state, Views.Document.runUpdateThumbnails document )

        Models.DidRunOcr _ ->
            ( state, Cmd.none )

        Models.DidRunUpdateThumbnails _ ->
            ( state, Cmd.none )

        Models.RunUpdateAll document ->
            ( state, Cmd.batch [ Views.Document.runOcr document, Views.Document.runUpdateThumbnails document ] )

        Models.ScrollToTop ->
            ( state
            , Cmd.map Models.ScrollToMsg <| ScrollTo.scrollToTop
            )

        Models.ScrollToMsg scrollToMsg ->
            let
                ( scrollToModel, scrollToCmds ) =
                    ScrollTo.update
                        scrollToMsg
                        state.scrollTo
            in
            ( { state | scrollTo = scrollToModel }
            , Cmd.map Models.ScrollToMsg scrollToCmds
            )

        Models.GotQueueInfo result ->
            Views.Settings.handleQueueInfo state result

        Models.Nop ->
            ( state, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Models.State -> Sub Models.Msg
subscriptions { modalVisibility, scrollTo } =
    Sub.batch
        [ Ports.Gates.uploadCompleted (always Models.UploadCompleted)
        , Ports.Gates.addTags Models.AddTags
        , Ports.Gates.removeTags Models.RemoveTags
        , Bootstrap.Modal.subscriptions modalVisibility Models.AnimatedModal
        , Sub.map ScrollToMsg <| ScrollTo.subscriptions scrollTo
        ]



-- VIEW


navbar : Html Models.Msg
navbar =
    Html.nav [ Html.Attributes.class "navbar navbar-expand-md navbar-dark sticky-top bg-dark" ]
        [ Html.a [ Html.Attributes.class "navbar-brand", Html.Attributes.href "/" ] [ Html.text "DMS42" ]
        , Html.button
            [ Html.Attributes.class "navbar-toggler"
            , Html.Attributes.type_ "button"
            , Html.Attributes.attribute "data-toggle" "collapse"
            , Html.Attributes.attribute "data-target" "#navBarNav"
            , Html.Attributes.attribute "aria-controls" "navBarNav"
            , Html.Attributes.attribute "aria-expanded" "false"
            , Html.Attributes.attribute "aria-label" "Toggle navigation"
            ]
            [ Html.span [ Html.Attributes.class "navbar-toggler-icon" ] []
            ]
        , Html.div
            [ Html.Attributes.class "collapse navbar-collapse"
            , Html.Attributes.id "navBarNav"
            ]
            [ Html.ul [ Html.Attributes.class "navbar-nav mr-auto" ]
                [ Html.li [ Html.Attributes.class "nav-item", Html.Attributes.classList [] ]
                    [ Html.a
                        [ Html.Attributes.class "nav-link"
                        , Html.Attributes.href "/"
                        ]
                        [ Html.text "Home" ]
                    ]
                , Html.li [ Html.Attributes.class "nav-item", Html.Attributes.classList [] ]
                    [ Html.a
                        [ Html.Attributes.class "nav-link"
                        , Html.Attributes.href "/documents"
                        ]
                        [ Html.text "Documents" ]
                    ]
                , Html.li [ Html.Attributes.class "nav-item", Html.Attributes.classList [] ]
                    [ Html.a
                        [ Html.Attributes.class "nav-link"
                        , Html.Attributes.href "/settings"
                        ]
                        [ Html.text "Settings" ]
                    ]
                ]
            ]
        ]


mainView : Models.State -> List (Html Models.Msg)
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

        mainContent =
            case state.error of
                Just x ->
                    [ Html.div []
                        [ Html.div [ Html.Attributes.class "error alert alert-danger" ] [ Html.text x ]
                        ]
                    , Html.div [] content
                    ]

                Nothing ->
                    content
    in
    [ navbar
    , Html.main_
        [ Html.Attributes.class "container-fluid"
        , Html.Attributes.attribute "role" "main"
        ]
        [ Html.div [ Html.Attributes.class "pt-5" ] mainContent ]
    ]


view : Models.State -> Browser.Document Models.Msg
view state =
    { title = "DMS42"
    , body = mainView state
    }
