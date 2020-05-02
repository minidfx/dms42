module Main exposing (init, main, subscriptions, update, view)

import Bootstrap.Modal
import Bootstrap.Navbar
import Browser
import Browser.Navigation as Nav
import Factories
import Html exposing (..)
import Html.Attributes exposing (..)
import Models
import Msgs.AddDocument
import Msgs.Document
import Msgs.Documents
import Msgs.Home
import Msgs.Main
import Msgs.Settings
import Ports.Gates
import ScrollTo
import Task
import Time
import Url exposing (Url)
import Url.Parser exposing (..)
import Url.Parser.Query
import Views.AddDocuments
import Views.Document
import Views.Documents
import Views.Home
import Views.Settings
import Views.Shared



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


routes : Url.Parser.Parser (Models.Route -> a) a
routes =
    Url.Parser.oneOf
        [ Url.Parser.map Models.Documents (Url.Parser.s "documents" <?> Url.Parser.Query.int "offset")
        , Url.Parser.map Models.AddDocuments (Url.Parser.s "documents" </> Url.Parser.s "add")
        , Url.Parser.map Models.Document (Url.Parser.s "documents" </> Url.Parser.string <?> Url.Parser.Query.int "offset")
        , Url.Parser.map Models.Settings (Url.Parser.s "settings")
        , Url.Parser.map Models.Home (Url.Parser.top <?> Url.Parser.Query.string "query")
        ]


init : () -> Url.Url -> Nav.Key -> ( Models.State, Cmd Msgs.Main.Msg )
init flags url key =
    let
        defaultActions =
            Task.perform Msgs.Main.GetUserTimeZone Time.here

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

        newCommands =
            Cmd.batch [ navBarCmd, defaultActions, commands ]
    in
    ( state, newCommands )



-- UPDATE


update : Msgs.Main.Msg -> Models.State -> ( Models.State, Cmd Msgs.Main.Msg )
update msg state =
    case msg of
        Msgs.Main.DocumentsMsg documentsMsg ->
            Views.Documents.update state documentsMsg Nothing

        Msgs.Main.HomeMsg homeMsg ->
            Views.Home.update state homeMsg Nothing

        Msgs.Main.SettingsMsg settingsMsg ->
            Views.Settings.update state settingsMsg

        Msgs.Main.DocumentMsg documentMsg ->
            Views.Document.update state documentMsg Nothing

        Msgs.Main.AddDocumentMsg addDocumentMsg ->
            Views.AddDocuments.update state addDocumentMsg

        Msgs.Main.GotTags result ->
            Views.Shared.handleTags state result

        Msgs.Main.LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( state, Nav.pushUrl state.key (Url.toString url) )

                Browser.External href ->
                    ( state, Nav.load href )

        Msgs.Main.UrlChanged url ->
            let
                route =
                    Url.Parser.parse routes url |> Maybe.withDefault (Models.Home Nothing)

                newState =
                    { state | url = url, route = route, error = Nothing }
            in
            case route of
                Models.AddDocuments ->
                    Views.AddDocuments.update newState Msgs.AddDocument.Home

                Models.Documents offset ->
                    Views.Documents.update
                        newState
                        Msgs.Documents.Home
                        offset

                Models.Document documentId _ ->
                    Views.Document.update
                        newState
                        Msgs.Document.Home
                        (Just documentId)

                Models.Settings ->
                    Views.Settings.update newState Msgs.Settings.Home

                Models.Home query ->
                    Views.Home.update newState Msgs.Home.Home query

        Msgs.Main.GetUserTimeZone zone ->
            ( { state | userTimeZone = Just zone }
            , Cmd.none
            )

        Msgs.Main.CloseModal ->
            ( { state | modalVisibility = Bootstrap.Modal.hidden }, Cmd.none )

        Msgs.Main.ShowModal ->
            ( { state | modalVisibility = Bootstrap.Modal.shown }, Cmd.none )

        Msgs.Main.AnimatedModal visibility ->
            ( { state | modalVisibility = visibility }, Cmd.none )

        Msgs.Main.ScrollToTop ->
            ( state
            , Cmd.map Msgs.Main.ScrollToMsg <| ScrollTo.scrollToTop
            )

        Msgs.Main.ScrollToMsg scrollToMsg ->
            let
                ( scrollToModel, scrollToCmds ) =
                    ScrollTo.update
                        scrollToMsg
                        state.scrollTo
            in
            ( { state | scrollTo = scrollToModel }
            , Cmd.map Msgs.Main.ScrollToMsg scrollToCmds
            )

        Msgs.Main.NavbarMsg navBarState ->
            ( { state | navBarState = navBarState }, Cmd.none )

        Msgs.Main.Nop ->
            ( state, Cmd.none )

        Msgs.Main.StartUpload ->
            ( state, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Models.State -> Sub Msgs.Main.Msg
subscriptions { modalVisibility, scrollTo, navBarState } =
    Sub.batch
        [ Ports.Gates.uploadCompleted (always <| Msgs.Main.AddDocumentMsg Msgs.AddDocument.UploadCompleted)
        , Ports.Gates.addTags <| Msgs.Main.DocumentMsg << Msgs.Document.AddTags
        , Ports.Gates.removeTags <| Msgs.Main.DocumentMsg << Msgs.Document.RemoveTags
        , Bootstrap.Modal.subscriptions modalVisibility Msgs.Main.AnimatedModal
        , Sub.map Msgs.Main.ScrollToMsg <| ScrollTo.subscriptions scrollTo
        , Bootstrap.Navbar.subscriptions navBarState Msgs.Main.NavbarMsg
        ]



-- VIEW


navbar : Models.State -> Html Msgs.Main.Msg
navbar state =
    let
        { navBarState } =
            state
    in
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
            [ yieldItem state "/" "Home"
            , yieldItem state "/documents" "Documents"
            , yieldItem state "/settings" "Settings"
            ]
        |> Bootstrap.Navbar.view navBarState


yieldItem : Models.State -> String -> String -> Bootstrap.Navbar.Item Msgs.Main.Msg
yieldItem { url } path name =
    if url.path == path then
        Bootstrap.Navbar.itemLinkActive [ Html.Attributes.href path ] [ Html.text name ]

    else
        Bootstrap.Navbar.itemLink [ Html.Attributes.href path ] [ Html.text name ]


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
