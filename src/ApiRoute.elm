module ApiRoute exposing (ApiRoute(..), from_url, parser, to_string)

import Url
import Url.Parser exposing ((</>), (<?>), Parser, map, oneOf, parse, s, top)
import Url.Parser.Query as Query


type ApiRoute
    = LastWishlist
    | NewProducts
    | ProductArchive (Maybe Int)


parser : Parser (ApiRoute -> a) a
parser =
    oneOf
        [ map LastWishlist (s "api" </> s "wishlist" </> s "last")
        , map NewProducts (s "api" </> s "product" </> s "newest")
        , map ProductArchive (s "api" </> s "product" </> s "archive" <?> Query.int "page")
        ]


from_url : Url.Url -> Maybe ApiRoute
from_url url =
    { url | path = url.path ++ Maybe.withDefault "" url.fragment, fragment = Nothing }
        |> parse parser


to_string : ApiRoute -> String
to_string route =
    let
        path_pieces =
            case route of
                LastWishlist ->
                    [ "api", "wishlist", "last" ]

                NewProducts ->
                    [ "api", "product", "newest" ]

                ProductArchive _ ->
                    [ "api", "product", "archive" ]

        query_pieces =
            case route of
                ProductArchive maybe_page ->
                    case maybe_page of
                        Just page ->
                            [ ( "page", String.fromInt page ) ]

                        Nothing ->
                            [ ( "page", "1" ) ]

                _ ->
                    []

        query =
            case List.length query_pieces of
                0 ->
                    ""

                _ ->
                    "?"
                        ++ String.join "&" (List.map (\p -> Tuple.first p ++ "=" ++ Tuple.second p) query_pieces)
    in
    "/" ++ String.join "/" path_pieces ++ query
