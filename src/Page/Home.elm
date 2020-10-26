module Page.Home exposing (Model, Msg, init, to_nav_key, update, view)

import Api.Product exposing (Product)
import Api.Wishlist
import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Route


type alias Model =
    { nav_key : Nav.Key
    , last_wishlist : Maybe Api.Wishlist.Wishlist
    , last_error : Maybe String
    }


type Msg
    = RequestLastWishlist
    | GotLastWishlist (Result Http.Error Api.Wishlist.Wishlist)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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
    ( { nav_key = nav_key, last_wishlist = Nothing, last_error = Nothing }, request_last_wishlist )


view : Model -> { title : String, content : Html Msg }
view model =
    let
        content =
            case model.last_wishlist of
                Just last_wishlist ->
                    view_product_table last_wishlist.products

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


view_product_table : List Product -> Html Msg
view_product_table products =
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
            ]

        items =
            List.sortBy (\p -> p.price) products
                |> List.reverse
                |> List.map to_list_item
                |> List.foldr (++) []
    in
    table [ class "table table-responsive table-sm" ]
        [ tbody [] items ]
