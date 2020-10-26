module Route exposing (Route(..), from_url, parser, to_string)

import Url
import Url.Parser exposing ((</>), Parser, map, oneOf, parse, s, top)


type Route
    = Home
    | ApiLastWishlist


parser : Parser (Route -> a) a
parser =
    oneOf
        [ map Home top
        , map ApiLastWishlist (s "api" </> s "wishlist" </> s "last")
        ]


from_url : Url.Url -> Maybe Route
from_url url =
    { url | path = url.path ++ Maybe.withDefault "" url.fragment, fragment = Nothing }
        |> parse parser


to_string : Route -> String
to_string route =
    let
        pieces =
            case route of
                Home ->
                    []

                ApiLastWishlist ->
                    [ "api", "wishlist", "last" ]
    in
    "/" ++ String.join "/" pieces
