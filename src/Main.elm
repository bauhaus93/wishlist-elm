module Main exposing (Model(..), Msg(..), change_route, init, main, subscriptions, update, update_with, view)

import Browser
import Browser.Navigation as Nav
import Html
import Page
import Page.Empty as Empty
import Page.Home as Home
import Route
import Url


type Model
    = Home Home.Model
    | Redirect Nav.Key


type Msg
    = UrlChanged Url.Url
    | LinkClicked Browser.UrlRequest
    | GotHomeMsg Home.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( UrlChanged url, _ ) ->
            change_route (Route.from_url url) model

        ( LinkClicked request, _ ) ->
            case request of
                Browser.Internal url ->
                    ( model, Nav.pushUrl (to_nav_key model) (Url.toString url) )

                Browser.External url ->
                    ( model, Nav.load url )

        ( GotHomeMsg sub_msg, Home home ) ->
            Home.update sub_msg home
                |> update_with Home GotHomeMsg model

        ( _, _ ) ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> Browser.Document Msg
view model =
    let
        view_page page to_msg config =
            let
                { title, body } =
                    Page.view page config
            in
            { title = title
            , body = List.map (Html.map to_msg) body
            }
    in
    case model of
        Home home ->
            view_page Page.Home GotHomeMsg (Home.view home)

        Redirect _ ->
            Page.view Page.Other Empty.view


to_nav_key : Model -> Nav.Key
to_nav_key model =
    case model of
        Home home ->
            Home.to_nav_key home

        Redirect nav_key ->
            nav_key


change_route : Maybe Route.Route -> Model -> ( Model, Cmd Msg )
change_route maybe_route model =
    case maybe_route of
        Nothing ->
            Home.init (to_nav_key model)
                |> update_with Home GotHomeMsg model

        Just Route.Home ->
            Home.init (to_nav_key model)
                |> update_with Home GotHomeMsg model

        Just Route.ApiLastWishlist ->
            Home.init (to_nav_key model)
                |> update_with Home GotHomeMsg model


update_with : (sub_model -> Model) -> (sub_msg -> Msg) -> Model -> ( sub_model, Cmd sub_msg ) -> ( Model, Cmd Msg )
update_with to_model to_msg model ( sub_model, sub_cmd ) =
    ( to_model sub_model
    , Cmd.map to_msg sub_cmd
    )


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url nav_key =
    change_route (Route.from_url url) (Redirect nav_key)


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }
