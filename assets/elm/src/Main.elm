module Main exposing (init, main, subscriptions, update, view)

import Browser
import Browser.Navigation as Nav
import Factories
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode
import Models exposing (DocumentsResponse)
import Ports.Gates
import Ports.Models
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
        , Url.Parser.map Models.Document (Url.Parser.s "documents" </> Url.Parser.string)
        , Url.Parser.map Models.Settings (Url.Parser.s "settings")
        , Url.Parser.map Models.Home (Url.Parser.s "/")
        ]


init : () -> Url.Url -> Nav.Key -> ( Models.State, Cmd Models.Msg )
init flags url key =
    let
        defaultActions =
            Task.perform Models.GetUserTimeZone Time.here

        route =
            Url.Parser.parse routes url |> Maybe.withDefault Models.Home

        initialState =
            Factories.stateFactory key url route

        ( state, commands ) =
            case route of
                Models.AddDocuments ->
                    Views.AddDocuments.init flags key initialState

                Models.Documents offset ->
                    Views.Documents.init flags key initialState offset

                Models.Document id ->
                    Views.Document.init flags key initialState id

                Models.Settings ->
                    ( initialState, Cmd.none )

                Models.Home ->
                    ( initialState, Cmd.none )

        newCommands =
            Cmd.batch [ defaultActions, commands ]
    in
    ( state, newCommands )



-- UPDATE


update : Models.Msg -> Models.State -> ( Models.State, Cmd Models.Msg )
update msg model =
    case msg of
        Models.PaginationMsg x ->
            ( model
            , Cmd.none
            )

        Models.GotDocuments documentsResult ->
            Views.Documents.handleDocuments model documentsResult

        Models.LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        Models.StartUpload ->
            ( { model | uploading = True }
            , Cmd.batch [ Views.AddDocuments.startUpload ]
            )

        Models.UploadCompleted ->
            ( { model | uploading = False }
            , Cmd.none
            )

        Models.UrlChanged url ->
            let
                route =
                    Url.Parser.parse routes url |> Maybe.withDefault Models.Home

                newModel =
                    { model | url = url, route = route, error = Nothing }
            in
            case route of
                Models.AddDocuments ->
                    Views.AddDocuments.update newModel

                Models.Documents offset ->
                    Views.Documents.update newModel offset

                Models.Document id ->
                    Views.Document.update newModel id

                Models.Settings ->
                    ( newModel, Cmd.none )

                Models.Home ->
                    ( newModel, Cmd.none )

        Models.GetUserTimeZone zone ->
            ( { model | userTimeZone = Just zone }
            , Cmd.none
            )

        Models.None ->
            ( model, Cmd.none )

        Models.AddTags { documentId, tags } ->
            ( model, Views.Document.addTags documentId tags )

        Models.RemoveTags { documentId, tags } ->
            ( model, Views.Document.removeTags documentId tags )

        Models.DidRemoveTags result ->
            ( model, Cmd.none )

        Models.DidAddTags result ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Models.State -> Sub Models.Msg
subscriptions _ =
    Sub.batch
        [ Ports.Gates.uploadCompleted (always Models.UploadCompleted)
        , Ports.Gates.addTags Models.AddTags
        , Ports.Gates.removeTags Models.RemoveTags
        ]



-- VIEW


navbar : Html Models.Msg
navbar =
    Html.nav [ Html.Attributes.class "navbar navbar-expand-md navbar-dark fixed-top bg-dark" ]
        [ Html.a [ Html.Attributes.class "navbar-brand", Html.Attributes.href "/" ] [ Html.text "DMS42" ]
        , Html.div [ Html.Attributes.class "collapse navbar-collapse" ]
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
        { route } =
            state

        content =
            case route of
                Models.Documents offset ->
                    Views.Documents.view state offset

                Models.Settings ->
                    Views.Settings.view state

                Models.AddDocuments ->
                    Views.AddDocuments.view state

                Models.Home ->
                    Views.Home.view state

                Models.Document id ->
                    Views.Document.view state id

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
        [ Html.div [ Html.Attributes.class "bd-dms42" ] mainContent ]
    ]


view : Models.State -> Browser.Document Models.Msg
view state =
    { title = "DMS42"
    , body = mainView state
    }
