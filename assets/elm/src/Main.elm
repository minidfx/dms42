module Main exposing (init, main, subscriptions, update, view)

import Bootstrap.Modal
import Bootstrap.Navbar
import Bootstrap.Spinner
import Bootstrap.Text
import Browser
import Browser.Dom
import Browser.Navigation as Nav
import Factories
import Helpers exposing (isSamePage)
import Html exposing (..)
import Html.Attributes exposing (..)
import Models
import Msgs.AddDocument
import Msgs.Document
import Msgs.Documents
import Msgs.Home
import Msgs.Main
import Msgs.Settings
import Msgs.Tags
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


routes : Url.Parser.Parser (Models.Route -> a) a
routes =
    Url.Parser.oneOf
        [ Url.Parser.map Models.Documents (Url.Parser.s "documents" <?> Url.Parser.Query.int "offset")
        , Url.Parser.map Models.AddDocuments (Url.Parser.s "documents" </> Url.Parser.s "add")
        , Url.Parser.map Models.Document (Url.Parser.s "documents" </> Url.Parser.string <?> Url.Parser.Query.int "offset")
        , Url.Parser.map Models.Settings (Url.Parser.s "settings")
        , Url.Parser.map Models.Tags (Url.Parser.s "tags")
        , Url.Parser.map Models.Home (Url.Parser.top <?> Url.Parser.Query.string "query")
        ]


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


update : Msgs.Main.Msg -> Models.State -> ( Models.State, Cmd Msgs.Main.Msg )
update msg state =
    case msg of
        Msgs.Main.TagsMsg tagsMsg ->
            Views.Tags.update state tagsMsg

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

        Msgs.Main.GotAndLoadTags result ->
            Views.Shared.handleTags state result True

        Msgs.Main.GotTags result ->
            Views.Shared.handleTags state result False

        Msgs.Main.LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( state, Nav.pushUrl state.key (Url.toString url) )

                Browser.External href ->
                    ( state, Nav.load href )

        Msgs.Main.UrlChanged url ->
            updateUrlChanged state url

        Msgs.Main.GotUserTimeZone zone ->
            ( { state | userTimeZone = Just zone }
            , Cmd.none
            )

        Msgs.Main.GotViewPort viewport ->
            ( { state | viewPort = Just viewport }, Cmd.none )

        Msgs.Main.CloseModal ->
            ( { state | modalVisibility = Nothing }, Cmd.none )

        Msgs.Main.ShowModal id ->
            ( { state | modalVisibility = Just <| Factories.modalFactory id Bootstrap.Modal.shown }, Cmd.none )

        Msgs.Main.AnimatedModal visibility ->
            case state.modalVisibility of
                Just modal ->
                    ( { state | modalVisibility = Just <| { modal | visibility = visibility } }, Cmd.none )

                Nothing ->
                    ( state, Cmd.none )

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


updateUrlChanged : Models.State -> Url.Url -> ( Models.State, Cmd Msgs.Main.Msg )
updateUrlChanged ({ tagsLoaded, modalVisibility, history } as state) url =
    let
        newHistory =
            url
                :: history
                |> List.take 10

        baseNewState =
            { state | history = newHistory }
    in
    case modalVisibility of
        Just x ->
            if x.visibility /= Bootstrap.Modal.hidden then
                ( baseNewState
                  -- INFO: Close the modal and then navigate to the URL.
                , (Msgs.Main.CloseModal |> Task.succeed)
                    |> Task.andThen (\_ -> Msgs.Main.UrlChanged url |> Task.succeed)
                    |> Task.perform identity
                )

            else
                ( baseNewState
                , Msgs.Main.UrlChanged url |> Task.succeed |> Task.perform identity
                )

        Nothing ->
            let
                previousUrl =
                    List.head history

                localIsSamePage =
                    previousUrl
                        |> Maybe.andThen (\u -> Just <| isSamePage u url)
                        |> Maybe.withDefault True
            in
            -- INFO: Make sure to clear the previous DOM element loaded with the tags.
            if not localIsSamePage && tagsLoaded then
                ( { baseNewState | tagsLoaded = False }
                , Cmd.batch
                    [ Ports.Gates.unloadTags { jQueryPath = "#tags" }
                    , Msgs.Main.UrlChanged url |> Task.succeed |> Task.perform identity
                    ]
                )

            else
                let
                    route =
                        Url.Parser.parse routes url |> Maybe.withDefault (Models.Home Nothing)

                    newState =
                        { baseNewState | url = url, route = route, error = Nothing }
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

                    Models.Tags ->
                        Views.Tags.update newState Msgs.Tags.Home



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
            [ yieldItem state "/" "Home"
            , yieldItem state "/tags" "Tags"
            , yieldItem state "/documents" "Documents"
            , yieldItem state "/settings" "Settings"
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


yieldItem : Models.State -> String -> String -> Bootstrap.Navbar.Item Msgs.Main.Msg
yieldItem { url } startWithPath name =
    if String.startsWith startWithPath url.path then
        Bootstrap.Navbar.itemLinkActive [ Html.Attributes.href startWithPath ] [ Html.text name ]

    else
        Bootstrap.Navbar.itemLink [ Html.Attributes.href startWithPath ] [ Html.text name ]


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
