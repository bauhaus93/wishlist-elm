module Api.Product exposing (Product, decoder, list_decoder)

import Api.Source as Source
import Json.Decode as D
import Json.Decode.Pipeline exposing (required)
import Json.Encode as E


type alias Product =
    { name : String
    , price : Int
    , quantity : Int
    , stars : Int
    , url : String
    , url_img : String
    , first_seen : Int
    , last_seen : Int
    , source : Source.Source
    }


decoder : D.Decoder Product
decoder =
    D.succeed Product
        |> required "name" D.string
        |> required "price" D.int
        |> required "quantity" D.int
        |> required "stars" D.int
        |> required "url" D.string
        |> required "url_img" D.string
        |> required "first_seen" D.int
        |> required "last_seen" D.int
        |> required "source" Source.decoder


list_decoder : D.Decoder (List Product)
list_decoder =
    D.list decoder
