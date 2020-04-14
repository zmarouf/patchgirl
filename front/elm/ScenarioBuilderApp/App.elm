module ScenarioBuilderApp.App exposing (..)

import Uuid
import Modal
import Modal exposing (Modal(..))
import Element exposing (..)
import Element.Font as Font
import Element.Background as Background
import Util exposing (..)
import Element.Border as Border
import Element.Events as Events
import Html.Events as Html
import Html as Html
import Html.Attributes as Html
import Html.Events.Extra exposing (targetValueIntParse)
import Json.Decode as Json
import Application.Model as Application

import Application.Type exposing (..)
import Page exposing(..)
import ScenarioBuilderApp.ScenarioBuilder.App as ScenarioBuilder
import ScenarioBuilderApp.ScenarioTree.App as ScenarioTree


-- * model


type alias Model a =
    { a
        | notification : Maybe String
        , whichModal : Maybe Modal
        , scenarioCollection : ScenarioCollection
        , requestCollection : RequestCollection
        , displayedScenarioNodeMenuId : Maybe Uuid.Uuid
        , environments : List Environment
        , selectedEnvironmentToRunIndex : Maybe Int
        , page : Page
    }


-- * message


type Msg
  = ScenarioBuilderMsg ScenarioBuilder.Msg
  | ScenarioTreeMsg ScenarioTree.Msg
  | EnvSelectionMsg Int


-- * update


update : Msg -> Model a -> (Model a, Cmd Msg)
update msg model =
    case msg of
        EnvSelectionMsg idx ->
            let
                newModel =
                    { model | selectedEnvironmentToRunIndex = Just idx }
            in
                (newModel, Cmd.none)

        ScenarioTreeMsg subMsg ->
            let
                (newModel, newSubMsg) = ScenarioTree.update subMsg model
            in
                (newModel, Cmd.map ScenarioTreeMsg newSubMsg)

        ScenarioBuilderMsg subMsg ->
            case getBuilder model of
                Just builder ->
                    let
                        (ScenarioCollection scenarioCollectionId scenarioNodes) =
                            model.scenarioCollection

                        (newBuilder, newSubMsg) =
                            ScenarioBuilder.update subMsg builder

                        newBuilderTree =
                            List.map (ScenarioTree.modifyScenarioNode builder.id (changeFileBuilder newBuilder)) scenarioNodes

                        newModel =
                            { model
                                | scenarioCollection = ScenarioCollection scenarioCollectionId newBuilderTree
                                , notification = newBuilder.notification
                                , whichModal = newBuilder.whichModal
                            }

                        newMsg =
                            Cmd.map ScenarioBuilderMsg newSubMsg
                    in
                        (newModel, newMsg)

                _ ->
                    (model, Cmd.none)


-- * util


getSelectedBuilderId : Model a -> Maybe Uuid.Uuid
getSelectedBuilderId model =
    case model.page of
        ScenarioPage (Just id) ->
            Just id

        _ ->
            Nothing

getBuilder : Model a -> Maybe ScenarioBuilder.Model
getBuilder model =
    let
        (ScenarioCollection scenarioCollectionId scenarioNodes) = model.scenarioCollection
        mFile : Maybe ScenarioFileRecord
        mFile = Maybe.andThen (ScenarioTree.findFile scenarioNodes) (getSelectedBuilderId model)
    in
        case mFile of
            Just file ->
                let
                    keyValuesToRun =
                        (Application.getEnvironmentKeyValuesToRun model)

                in
                    Just (convertFromFileToBuilder file scenarioCollectionId model.requestCollection keyValuesToRun model.notification model.whichModal)

            _ ->
                Nothing

convertFromFileToBuilder : ScenarioFileRecord
                         -> Uuid.Uuid
                         -> RequestCollection
                         -> List (Storable NewKeyValue KeyValue)
                         -> Maybe String
                         -> Maybe Modal
                         -> ScenarioBuilder.Model
convertFromFileToBuilder file scenarioCollectionId requestCollection keyValuesToRun notification whichModal =
    { notification = notification
    , whichModal = whichModal
    , id = file.id
    , scenarioCollectionId = scenarioCollectionId
    , requestCollection = requestCollection
    , scenes = file.scenes
    , keyValues = keyValuesToRun
    , name = file.name
    }

convertFromBuilderToFile : ScenarioBuilder.Model -> ScenarioFileRecord
convertFromBuilderToFile builder =
    { id = builder.id
    , name = builder.name
    , scenes = builder.scenes
    }

changeFileBuilder : ScenarioBuilder.Model -> ScenarioNode -> ScenarioNode
changeFileBuilder builder node =
    case node of
        ScenarioFolder f ->
            ScenarioFolder f
        ScenarioFile f ->
            ScenarioFile (convertFromBuilderToFile builder)

-- * view


view : Model a -> Element Msg
view model =
    wrappedRow [ width fill
               , paddingXY 10 0
               , spacing 10
               ]
        [ column [ alignTop
                 , spacing 20
                 , centerX
                 , padding 20
                 , width (fillPortion 1)
                 , Background.color white
                 , boxShadow
                 ]
              [ el [ ] <| envSelectionView <| List.map .name model.environments
              , el [ paddingXY 10 0 ] (map ScenarioTreeMsg (ScenarioTree.view model))
              ]
        , builderView model
        ]

envSelectionView : List (Editable String) -> Element Msg
envSelectionView environmentNames =
    let
        entryView : Int -> Editable String -> Html.Html Msg
        entryView idx envName =
            Html.option [ Html.value (String.fromInt idx) ] [ Html.text (editedOrNotEditedValue envName) ]
    in
        html <|
            Html.div []
                [ Html.label [] [ Html.text "Env: " ]
                , Html.select [ Html.on "change" (Json.map EnvSelectionMsg targetValueIntParse) ]
                    (List.indexedMap entryView environmentNames)
                ]

builderView : Model a -> Element Msg
builderView model =
    case getBuilder model of
        Just builder ->
            el [ width (fillPortion 9), centerX, centerY, alignTop ]
                (map ScenarioBuilderMsg (ScenarioBuilder.view builder))

        Nothing ->
            el [ width (fillPortion 9), centerX, centerY ]
                ( el [centerX ] (text "No scenario selected") )