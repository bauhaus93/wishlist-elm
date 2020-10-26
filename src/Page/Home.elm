module Page.Home exposing (Model, Msg, init, to_nav_key, update, view)

import Api.Product exposing (Product)
import Api.Wishlist
import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Route
import Task
import Time


type alias Model =
    { nav_key : Nav.Key
    , time : Maybe Int
    , last_wishlist : Maybe Api.Wishlist.Wishlist
    , last_error : Maybe String
    }


type Msg
    = RequestLastWishlist
    | GotLastWishlist (Result Http.Error Api.Wishlist.Wishlist)
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
                    case e of
                        Http.BadBody err_msg ->
                            ( { model | last_error = Just err_msg }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

        RequestLastWishlist ->
            ( model, request_last_wishlist )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


to_nav_key : Model -> Nav.Key
to_nav_key model =
    model.nav_key


request_last_wishlist : Cmd Msg
request_last_wishlist =
    Http.get
        { url = Route.to_string Route.ApiLastWishlist
        , expect = Http.expectJson GotLastWishlist Api.Wishlist.decoder
        }


init : Nav.Key -> ( Model, Cmd Msg )
init nav_key =
    ( { nav_key = nav_key, time = Nothing, last_wishlist = Nothing, last_error = Nothing }, Task.perform GotTime Time.now )


view : Model -> { title : String, content : Html Msg }
view model =
    let
        content =
            case model.last_wishlist of
                Just last_wishlist ->
                    view_product_table model last_wishlist.products

                Nothing ->
                    case model.last_error of
                        Just e ->
                            text e

                        Nothing ->
                            text "Got None error"
    in
    { title = "home"
    , content = content
    }


view_price_quantity : Product -> Html Msg
view_price_quantity prod =
    text
        ("€ "
            ++ String.fromFloat (toFloat prod.price / 100.0)
            ++ (case prod.quantity of
                    1 ->
                        ""

                    n ->
                        " x " ++ String.fromInt n
               )
        )


month_to_num : Time.Month -> Int
month_to_num mon =
    case mon of
        Time.Jan ->
            1

        Time.Feb ->
            2

        Time.Mar ->
            3

        Time.Apr ->
            4

        Time.May ->
            5

        Time.Jun ->
            6

        Time.Jul ->
            7

        Time.Aug ->
            8

        Time.Sep ->
            9

        Time.Oct ->
            10

        Time.Nov ->
            11

        Time.Dec ->
            12


view_first_seen : Product -> Html Msg
view_first_seen prod =
    let
        first_seen =
            Time.millisToPosix (prod.first_seen * 1000)

        year =
            String.fromInt <|
                Time.toYear Time.utc first_seen

        month =
            String.fromInt <|
                month_to_num <|
                    Time.toMonth Time.utc first_seen

        day =
            String.fromInt <|
                Time.toDay Time.utc first_seen
    in
    text <|
        day
            ++ "."
            ++ month
            ++ "."
            ++ year


view_duration : Product -> Maybe Int -> Html Msg
view_duration prod maybe_now =
    let
        duration =
            case maybe_now of
                Just now ->
                    now - prod.first_seen

                Nothing ->
                    0

        thresholds =
            [ { t = 7 * 24 * 3600, u = "w" }, { t = 24 * 3600, u = "d" }, { t = 3600, u = "h" }, { t = 1, u = "s" } ]
    in
    text <|
        case List.head (List.filter (\d -> d.d > 0) <| List.map (\t -> { d = duration // t.t, u = t.u }) thresholds) of
            Just d ->
                String.fromInt d.d ++ d.u

            Nothing ->
                "0s"


view_product_table : Model -> List Product -> Html Msg
view_product_table model products =
    let
        to_list_item : Product -> List (Html Msg)
        to_list_item prod =
            [ tr []
                [ td [] [ img [ src prod.url_img, class "img-responsive", alt "Produktbild" ] [] ]
                , th [ attribute "colspan" "2", class "align-middle" ] [ a [ href prod.url, target "_blank" ] [ text prod.name ] ]
                ]
            , tr []
                [ th [] [ text "Wert" ]
                , td [] [ view_price_quantity prod ]
                ]
            , tr []
                [ th [] [ text "Zweck" ]
                , td [] [ a [ href prod.source.url, target "_blank" ] [ text prod.source.name ] ]
                ]
            , tr []
                [ th [] [ text "Vorhanden seit" ]
                , td [] [ view_first_seen prod ]
                ]
            , tr []
                [ th [] [ text "Dauer" ]
                , td [] [ view_duration prod model.time ]
                ]
            ]

        items =
            List.sortBy (\p -> p.price) products
                |> List.reverse
                |> List.map to_list_item
                |> List.foldr (++) []
    in
    table [ class "table table-responsive table-sm" ]
        [ tbody [] items ]
