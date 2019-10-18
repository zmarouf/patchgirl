module Window.Model exposing (..)

import MainNavBar.Model as MainNavBar
import RequestRunner.Model as RequestRunner
import EnvironmentKeyValueEdition.Model as EnvironmentKeyValueEdition
import EnvironmentEdition.Util as EnvironmentEdition
import VarApp.Model as VarApp
import BuilderApp.Model as BuilderApp
import List.Extra as List
import Window.Type as Type

type alias Model =
  { mainNavBarModel : MainNavBar.Model
  -- BUILDER APP
  , selectedBuilderIndex : Maybe Int
  , displayedBuilderIndex : Maybe Int
  , displayedRequestNodeMenuIndex : Maybe Int
  , tree : List BuilderApp.RequestNode
  -- POSTMAN
  , postmanModel : Maybe (List BuilderApp.RequestNode)
  -- ENVIRONMENT
  , selectedEnvironmentToRunIndex : Maybe Int
  , selectedEnvironmentToEditIndex : Maybe Int
  , selectedEnvironmentToRenameIndex : Maybe Int
  , environments : List Type.Environment
  , envModel : EnvironmentKeyValueEdition.Model
  -- VARIABLE APP
  , varAppModel : VarApp.Model
  -- RUNNER
  , runnerModel : RequestRunner.Model
  }

getEnvironmentToRun : Model -> Maybe Type.Environment
getEnvironmentToRun model =
    let
        selectEnvironment : Int -> Maybe Type.Environment
        selectEnvironment idx = List.getAt idx model.environments
    in
        Maybe.andThen selectEnvironment model.selectedEnvironmentToRunIndex

getEnvironmentKeyValuesToRun : Model -> List(String, String)
getEnvironmentKeyValuesToRun model =
    (getEnvironmentToRun model) |> Maybe.map .keyValues |> Maybe.withDefault []

getEnvironmentKeyValuesToEdit : Model -> List(String, String)
getEnvironmentKeyValuesToEdit model =
    (EnvironmentEdition.getEnvironmentToEdit model) |> Maybe.map .keyValues |> Maybe.withDefault []

defaultModel : Model
defaultModel =
  let
      selectedBuilderIndex = Just 4
      displayedBuilderIndex = Just 4
      displayedRequestNodeMenuIndex = Nothing
      tree = BuilderApp.defaultBuilderTree
      envModel : EnvironmentKeyValueEdition.Model
      envModel = [("url", "swapi.co")]
      varAppModel =
          { vars =
                [ ("key0", "value0")
                , ("key1", "value1")
                , ("key2", "value2")
                , ("key3", "value3")
                , ("key4", "value4")
                ]
          , overZoneId = Nothing
          , draggedId = Nothing
          }
      selectedEnvironmentToEditIndex = Just 0
      selectedEnvironmentToRunIndex = Just 0
      selectedEnvironmentToRenameIndex = Nothing
      environments =
          [ { name = "staging1"
            , keyValues = [("key1", "value1")]
            }
          , { name = "staging2"
            , keyValues = []
            }
          ]
  in
      { mainNavBarModel = MainNavBar.defaultModel
      , selectedBuilderIndex = selectedBuilderIndex
      , displayedBuilderIndex = displayedBuilderIndex
      , displayedRequestNodeMenuIndex = displayedRequestNodeMenuIndex
      , tree = tree
      , postmanModel = Nothing
      , selectedEnvironmentToRunIndex = selectedEnvironmentToRunIndex
      , selectedEnvironmentToEditIndex = selectedEnvironmentToEditIndex
      , selectedEnvironmentToRenameIndex = selectedEnvironmentToRenameIndex
      , environments = environments
      , envModel = envModel
      , runnerModel = Nothing
      , varAppModel = varAppModel
      }
