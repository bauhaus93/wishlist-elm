module Page.NewProducts exposing (..)

import Api.Product exposing (Product)
import ApiRoute
import Browser
import Browser.Navigation as Nav
import Error
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Page exposing (ViewInfo)
import ProductTable exposing (view_product_table)
import Route
import Task
import Time
import Utility exposing (timestamp_to_dmy)


type alias Model =
    { nav_key : Nav.Key
    , new_products : Maybe (List Product)
    , last_error : Maybe Error.Error
    }


type Msg
    = RequestNewProducts
    | GotNewProducts (Result Http.Error (List Product))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotNewProducts result ->
            case result of
                Ok products ->
                    ( { model | new_products = Just products }, Cmd.none )

                Err e ->
                    ( { model | last_error = Just (Error.HttpRequest e) }, Route.replace_url (to_nav_key model) Route.Error )

        RequestNewProducts ->
            ( model, request_new_products )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> ViewInfo Msg
view model =
    let
        product_table =
            case model.new_products of
                Just products ->
                    view_product_table True <|
                        List.reverse <|
                            List.sortBy (\p -> p.first_seen) products

                Nothing ->
                    div [] []
    in
    { title = "{{ PAGE.TITLE }}"
    , caption = "{{ PAGE.NEW_PRODUCTS.CAPTION }}"
    , content = product_table
    }


to_nav_key : Model -> Nav.Key
to_nav_key model =
    model.nav_key


to_last_error : Model -> Maybe Error.Error
to_last_error model =
    model.last_error


request_new_products : Cmd Msg
request_new_products =
    Http.get
        { url = ApiRoute.to_string ApiRoute.NewProducts
        , expect = Http.expectJson GotNewProducts Api.Product.list_decoder
        }


init : Nav.Key -> ( Model, Cmd Msg )
init nav_key =
    ( { nav_key = nav_key
      , new_products = Nothing
      , last_error = Nothing
      }
    , request_new_products
    )
