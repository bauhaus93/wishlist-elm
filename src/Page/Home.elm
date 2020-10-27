module Page.Home exposing (Model, Msg, init, to_last_error, to_nav_key, update, view)

import Api.Product exposing (Product)
import Api.Wishlist exposing (Wishlist)
import ApiRoute
import Browser
import Browser.Navigation as Nav
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
    , time : Maybe Int
    , last_wishlist : Maybe Wishlist
    , last_error : Maybe Http.Error
    }


type Msg
    = RequestLastWishlist
    | GotLastWishlist (Result Http.Error Wishlist)
    | GotTime Time.Posix


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTime time ->
            ( { model | time = Just (Time.posixToMillis time // 1000) }, request_last_wishlist )

        GotLastWishlist result ->
            case result of
                Ok wishlist ->
                    ( { model | last_wishlist = Just wishlist }, Cmd.none )

                Err e ->
                    ( { model | last_error = Just e }, Nav.pushUrl (to_nav_key model) (Route.to_string Route.Error) )

        RequestLastWishlist ->
            ( model, request_last_wishlist )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> ViewInfo Msg
view model =
    let
        product_table =
            case model.last_wishlist of
                Just last_wishlist ->
                    [ view_wishlist_info last_wishlist, view_product_table model.time last_wishlist.products ]

                Nothing ->
                    [ h2 [] [ text "Lade Wunschliste..." ] ]

        time_string =
            case model.time of
                Just time ->
                    timestamp_to_dmy time

                Nothing ->
                    "Unbekannt"
    in
    { title = "Aktuell"
    , caption = "Forderungen vom " ++ time_string
    , content = div [] product_table
    }


to_nav_key : Model -> Nav.Key
to_nav_key model =
    model.nav_key


to_last_error : Model -> Maybe Http.Error
to_last_error model =
    model.last_error


request_last_wishlist : Cmd Msg
request_last_wishlist =
    Http.get
        { url = ApiRoute.to_string ApiRoute.LastWishlist
        , expect = Http.expectJson GotLastWishlist Api.Wishlist.decoder
        }


init : Nav.Key -> ( Model, Cmd Msg )
init nav_key =
    ( { nav_key = nav_key
      , time = Nothing
      , last_wishlist = Nothing
      , last_error = Nothing
      }
    , Task.perform GotTime Time.now
    )


view_wishlist_info : Wishlist -> Html Msg
view_wishlist_info wishlist =
    let
        view_row : String -> String -> Html Msg
        view_row caption value =
            tr []
                [ th [] [ text caption ]
                , td [] [ text value ]
                ]
    in
    table [ class "table table-responsive table-sm" ]
        [ tbody []
            [ view_row "Anzahl" (String.fromInt <| List.length wishlist.products)
            , view_row "Wert" (String.fromFloat <| toFloat wishlist.value / 100.0)
            ]
        ]
