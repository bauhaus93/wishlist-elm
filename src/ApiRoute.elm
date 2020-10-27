module ApiRoute exposing (ApiRoute(..), from_url, parser, to_string)

import Url
import Url.Parser exposing ((</>), Parser, map, oneOf, parse, s, top)


type ApiRoute
    = LastWishlist
    | NewProducts


parser : Parser (ApiRoute -> a) a
parser =
    oneOf
        [ map LastWishlist (s "api" </> s "wishlist" </> s "last")
        , map NewProducts (s "api" </> s "product" </> s "newest")
        ]


from_url : Url.Url -> Maybe ApiRoute
from_url url =
    { url | path = url.path ++ Maybe.withDefault "" url.fragment, fragment = Nothing }
        |> parse parser


to_string : ApiRoute -> String
to_string route =
    let
        pieces =
            case route of
                LastWishlist ->
                    [ "api", "wishlist", "last" ]

                NewProducts ->
                    [ "api", "product", "newest" ]
    in
    "/" ++ String.join "/" pieces
