module Page.Archive exposing (Model, Msg, init, to_last_error, to_nav_key, update, view)

import Api.Product exposing (Product)
import ApiRoute
import Browser
import Browser.Navigation as Nav
import Error
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Page exposing (ViewInfo)
import Pagination
import ProductTable exposing (view_product_table)
import Route
import Task
import Time
import Utility exposing (timestamp_to_dmy, wrap_row_col)


type alias Model =
    { nav_key : Nav.Key
    , pagination : Pagination.Model Product
    , last_error : Maybe Error.Error
    }


type Msg
    = GotPaginationMsg (Pagination.Msg Product)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotPaginationMsg sub_msg ->
            let
                updated =
                    Pagination.update sub_msg model.pagination
                        |> update_with (\m -> \sm -> { m | pagination = sm }) GotPaginationMsg model
            in
            case Pagination.to_last_error (Tuple.first updated).pagination of
                Just err ->
                    ( { model | last_error = Just err }, Route.replace_url (to_nav_key model) Route.Error )

                Nothing ->
                    updated


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> ViewInfo Msg
view model =
    let
        pagination =
            Pagination.view model.pagination
                |> Html.map GotPaginationMsg

        product_table =
            view_product_table True (Pagination.to_items model.pagination)
    in
    { title = "{{ PAGE.TITLE }}"
    , caption = " {{ PAGE.ARCHIVE.CAPTION }}"
    , content = div [] [ wrap_row_col product_table, wrap_row_col pagination ]
    }


update_with : (Model -> sub_model -> Model) -> (sub_msg -> Msg) -> Model -> ( sub_model, Cmd sub_msg ) -> ( Model, Cmd Msg )
update_with to_model to_msg model ( sub_model, sub_cmd ) =
    ( to_model model sub_model
    , Cmd.map to_msg sub_cmd
    )


to_nav_key : Model -> Nav.Key
to_nav_key model =
    model.nav_key


to_last_error : Model -> Maybe Error.Error
to_last_error model =
    model.last_error


to_pagination : Model -> Pagination.Model Product
to_pagination model =
    model.pagination


init : Nav.Key -> ( Model, Cmd Msg )
init nav_key =
    let
        initial_pagination =
            Pagination.init (\page -> \per_page -> ApiRoute.ProductArchive { page = Just page, per_page = Just per_page }) Api.Product.decoder

        initial_model =
            { nav_key = nav_key
            , pagination = initial_pagination
            , last_error = Nothing
            }

        updated_model =
            Pagination.update (Pagination.ExactPage 1) initial_pagination
                |> update_with (\m -> \sm -> { m | pagination = sm }) GotPaginationMsg initial_model
    in
    updated_model
