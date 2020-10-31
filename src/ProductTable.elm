module ProductTable exposing (view_product_table)

import Api.Product exposing (Product)
import Html exposing (..)
import Html.Attributes exposing (..)
import Time
import Utility exposing (month_to_num, timestamp_to_dmy)


view_product_table : List Product -> Html msg
view_product_table products =
    let
        items =
            List.sortBy (\p -> p.price) products
                |> List.reverse
                |> List.map to_list_item
                |> List.foldr (++) []

        to_list_item : Product -> List (Html msg)
        to_list_item prod =
            [ tr []
                [ td [] [ img [ src prod.url_img, class "img-responsive", alt "{{ PRODUCT_IMG_ALT }}" ] [] ]
                , th [ attribute "colspan" "2", class "align-middle" ] [ a [ href prod.url, target "_blank" ] [ text prod.name ] ]
                ]
            , view_row "{{ LABEL.VALUE }}" <| text (get_price_quantity prod)
            , view_row "{{ LABEL.WISHLIST_NAME }}" <| a [ href prod.source.url, target "_blank" ] [ text prod.source.name ]
            , view_row "{{ LABEL.DATE_RANGE }}" <| text (get_date_range prod)
            , view_row "{{ LABEL.DURATION }}" <| text (get_duration prod)
            ]

        view_row : String -> Html msg -> Html msg
        view_row caption value =
            tr []
                [ th [] [ text caption ]
                , td [] [ value ]
                ]
    in
    table [ class "table table-responsive table-sm" ]
        [ tbody [] items ]


get_price_quantity : Product -> String
get_price_quantity prod =
    let
        quantity =
            case prod.quantity of
                1 ->
                    ""

                n ->
                    " x " ++ String.fromInt n
    in
    String.join ""
        [ "€ "
        , String.fromFloat (toFloat prod.price / 100.0)
        , quantity
        ]


get_date_range : Product -> String
get_date_range prod =
    get_first_seen prod ++ " - " ++ get_last_seen prod


get_first_seen : Product -> String
get_first_seen prod =
    timestamp_to_dmy prod.first_seen


get_last_seen : Product -> String
get_last_seen prod =
    timestamp_to_dmy prod.last_seen


get_duration : Product -> String
get_duration prod =
    let
        duration =
            prod.last_seen - prod.first_seen

        thresholds =
            [ { t = 7 * 24 * 3600, u = "{{ TIME.WEEKS }}" }
            , { t = 24 * 3600, u = "{{ TIME.DAYS }}" }
            , { t = 3600, u = "{{ TIME.HOURS }}" }
            , { t = 60, u = "{{ TIME.MINUTES }}" }
            , { t = 1, u = "{{ TIME.SECONDS }}" }
            ]
    in
    case
        List.map (\t -> { d = duration // t.t, u = t.u }) thresholds
            |> List.filter (\d -> d.d > 0)
            |> List.head
    of
        Just d ->
            String.fromInt d.d
                ++ " "
                ++ (case d.d of
                        1 ->
                            String.slice 0 -1 d.u

                        _ ->
                            d.u
                   )

        Nothing ->
            "{{ TIME.UNKNOWN }}"
