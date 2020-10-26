module Api.Product exposing (Product, decoder)

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
    , item_id : String
    , first_seen : Int
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
        |> required "item_id" D.string
        |> required "first_seen" D.int
        |> required "source" Source.decoder
