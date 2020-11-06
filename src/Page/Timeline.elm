module Page.Timeline exposing (Model, Msg, init, to_last_error, to_nav_key, update, view)

import Api.Datapoint exposing (Datapoint)
import ApiRoute
import Browser
import Browser.Navigation as Nav
import Error
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import LineChart
import LineChart.Area as Area
import LineChart.Axis as Axis
import LineChart.Axis.Intersection as Intersection
import LineChart.Axis.Line as AxisLine
import LineChart.Axis.Range as Range
import LineChart.Axis.Tick as Tick
import LineChart.Axis.Ticks as Ticks
import LineChart.Axis.Title as Title
import LineChart.Colors as Colors
import LineChart.Container as Container
import LineChart.Dots as Dots
import LineChart.Events as Events
import LineChart.Grid as Grid
import LineChart.Interpolation as Interpolation
import LineChart.Junk as Junk
import LineChart.Legends as Legends
import LineChart.Line as Line
import Page exposing (ViewInfo)
import Route
import Task
import Time
import Utility exposing (timestamp_to_dm, timestamp_to_hm, wrap_row_col, wrap_row_col_centered)


type alias Model =
    { nav_key : Nav.Key
    , time : Maybe Int
    , datapoints : Maybe (List Datapoint)
    , last_error : Maybe Error.Error
    }


type Msg
    = RequestLastDay
    | RequestLastWeek
    | RequestLastMonth
    | RequestLast3Month
    | RequestLastYear
    | GotTime Time.Posix
    | GotDatapoints (Result Http.Error (List Datapoint))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTime time ->
            let
                timestamp =
                    Just (Time.posixToMillis time // 1000)
            in
            ( { model | time = timestamp }, request_days 1 timestamp )

        GotDatapoints result ->
            case result of
                Ok data ->
                    ( { model | datapoints = Just data }, Cmd.none )

                Err e ->
                    ( { model | last_error = Just (Error.HttpRequest e) }, Nav.pushUrl (to_nav_key model) (Route.to_string Route.Error) )

        RequestLastDay ->
            ( model, request_days 1 model.time )

        RequestLastWeek ->
            ( model, request_weeks 1 model.time )

        RequestLastMonth ->
            ( model, request_months 1 model.time )

        RequestLast3Month ->
            ( model, request_months 3 model.time )

        RequestLastYear ->
            ( model, request_years 1 model.time )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> ViewInfo Msg
view model =
    { title = "{{ PAGE.TITLE }}"
    , caption = "{{ PAGE.TIMELINE.CAPTION }}"
    , content = div [] [ wrap_row_col <| view_chart model.datapoints, wrap_row_col_centered <| view_request_buttons ]
    }


view_request_buttons : Html Msg
view_request_buttons =
    let
        timespan_button : Msg -> Bool -> String -> Html Msg
        timespan_button msg is_active label_string =
            label [ class "btn btn-secondary" ]
                [ input [ type_ "radio", name "timespan", attribute "autocomplete" "off", onClick msg ] []
                , text label_string
                ]

        request_buttons =
            [ timespan_button RequestLastDay True "{{ LABEL.LAST_DAY }}"
            , timespan_button RequestLastWeek False "{{ LABEL.LAST_WEEK }}"
            , timespan_button RequestLastMonth False "{{ LABEL.LAST_MONTH }}"
            , timespan_button RequestLast3Month False "{{ LABEL.LAST_3MONTH }}"
            , timespan_button RequestLastYear False "{{ LABEL.LAST_YEAR }}"
            ]
    in
    div []
        [ div [ class "d-sm-none btn-group-vertical btn-group-toggle", attribute "data-toggle" "buttons" ] request_buttons
        , div [ class "d-none d-sm-block btn-group btn-group-toggle", attribute "data-toggle" "buttons" ] request_buttons
        ]


view_chart : Maybe (List Datapoint) -> Html Msg
view_chart maybe_datapoints =
    case maybe_datapoints of
        Just datapoints ->
            let
                slices =
                    List.map (\d -> d.slice) datapoints

                high =
                    List.maximum slices
                        |> Maybe.withDefault 0

                low =
                    List.minimum slices
                        |> Maybe.withDefault 0

                timespan =
                    high - low

                chart_config =
                    { x = x_axis_config timespan
                    , y = Axis.default 400 "{{ LABEL.VALUE }}" .value
                    , container = Container.responsive "chart-1"
                    , interpolation = Interpolation.monotone
                    , intersection = Intersection.default
                    , legends = Legends.none
                    , events = Events.default
                    , junk = Junk.default
                    , grid = Grid.default
                    , area = Area.default
                    , line = Line.wider 2.0
                    , dots = Dots.default
                    }

                prepared_datapoints =
                    List.map (\d -> { slice = d.slice, value = toFloat d.value / 100.0 }) datapoints
            in
            LineChart.viewCustom chart_config [ LineChart.line Colors.blue Dots.none "{{ LABEL.VALUE }}" prepared_datapoints ]

        Nothing ->
            div [] []


x_axis_config : Int -> Axis.Config { slice : Int, value : Float } msg
x_axis_config timespan =
    Axis.custom
        { title = Title.default "{{ LABEL.TIME }}"
        , variable = \d -> Just (toFloat d.slice)
        , pixels = 600
        , range = Range.default
        , axisLine = AxisLine.full Colors.black
        , ticks = Ticks.intCustom 6 (custom_tick timespan)
        }


custom_tick : Int -> Int -> Tick.Config msg
custom_tick timespan n =
    let
        formatter : Int -> String
        formatter =
            case timespan <= 48 * 3600 of
                True ->
                    \v -> timestamp_to_hm (v - modBy 3600 v)

                False ->
                    timestamp_to_dm
    in
    Tick.custom
        { position = toFloat n
        , color = Colors.black
        , width = 2
        , length = 2
        , grid = True
        , direction = Tick.negative
        , label = Just (Junk.label Colors.black (formatter n))
        }


to_nav_key : Model -> Nav.Key
to_nav_key model =
    model.nav_key


to_last_error : Model -> Maybe Error.Error
to_last_error model =
    model.last_error


request_datapoints : ApiRoute.TimelineQuery -> Cmd Msg
request_datapoints query =
    Http.get
        { url = ApiRoute.to_string (ApiRoute.Timeline query)
        , expect = Http.expectJson GotDatapoints Api.Datapoint.list_decoder
        }


request_days : Int -> Maybe Int -> Cmd Msg
request_days days_past maybe_now =
    let
        points =
            case days_past >= 365 of
                True ->
                    50

                False ->
                    20
    in
    request_datapoints
        { from_timestamp =
            maybe_now
                |> Maybe.andThen (\n -> Just (n - days_past * 24 * 3600))
        , count = Just points
        }


request_weeks : Int -> Maybe Int -> Cmd Msg
request_weeks weeks_past =
    request_days (7 * weeks_past)


request_months : Int -> Maybe Int -> Cmd Msg
request_months months_past =
    request_weeks (4 * months_past)


request_years : Int -> Maybe Int -> Cmd Msg
request_years years_past =
    request_days (365 * years_past)


init : Nav.Key -> ( Model, Cmd Msg )
init nav_key =
    ( { nav_key = nav_key
      , time = Nothing
      , datapoints = Nothing
      , last_error = Nothing
      }
    , Task.perform GotTime Time.now
    )
