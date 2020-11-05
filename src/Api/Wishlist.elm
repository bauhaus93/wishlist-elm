module Api.Wishlist exposing (Wishlist, decoder)

import Api.Product as Product
import Json.Decode as D
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as E


type alias Wishlist =
    { timestamp : Int
    , products : List Product.Product
    }


decoder : D.Decoder Wishlist
decoder =
    D.succeed Wishlist
        |> required "timestamp" D.int
        |> required "products" (D.list Product.decoder)
