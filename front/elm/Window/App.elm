module Window.App exposing (..)

import Window.Model exposing (..)
import Window.Message exposing (..)
import Window.StateHandler exposing (..)

import Builder.App as Builder
import Builder.Model as Builder
import Builder.Message as Builder

import Builders.App as Builders
import Builders.Message as Builders

import BuilderTree.View as BuilderTree
import BuilderTree.Model as BuilderTree
import BuilderTree.Message as BuilderTree
import BuilderTree.App as BuilderTree

import Postman.View as Postman
import Postman.Model as Postman
import Postman.Message as Postman
import Postman.App as Postman

import Env.View as Env
import Env.Model as Env
import Env.Message as Env
import Env.App as Env

import EnvNav.View as EnvNav
import EnvNav.Model as EnvNav
import EnvNav.Message as EnvNav
import EnvNav.App as EnvNav
import EnvNav.Util as EnvNav

import EnvSelection.View as EnvSelection
import EnvSelection.Model as EnvSelection
import EnvSelection.Message as EnvSelection
import EnvSelection.App as EnvSelection

import RequestRunner.App as RequestRunner
import RequestRunner.Message as RequestRunner
import RequestRunner.Model as RequestRunner

import MainNavBar.Model as MainNavBar
import MainNavBar.View as MainNavBar
import MainNavBar.Message as MainNavBar
import MainNavBar.App as MainNavBar

import VarApp.Model as VarApp
import VarApp.View as VarApp
import VarApp.Message as VarApp
import VarApp.App as VarApp

import Window.View exposing(..)
import Window.Model exposing(..)

init : () -> (Model, Cmd Msg)
init _ =
  (defaultModel, Cmd.none)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    BuilderTreeMsg subMsg ->
      case BuilderTree.update subMsg model.treeModel of
        (newBuilderTreeModel, newMsg) -> ( { model | treeModel = newBuilderTreeModel }, Cmd.map BuilderTreeMsg newMsg)

    EnvNavMsg subMsg ->
      case EnvNav.update subMsg model.envNavModel of
        (newEnvNavModel, newMsg) ->
          let
            selectedEnvModel = model.selectedEnvModel
            newSelectedEnvModel = { selectedEnvModel | envs = List.map .name newEnvNavModel.envs }
          in
            ( { model | envNavModel = newEnvNavModel, selectedEnvModel = newSelectedEnvModel }
            , Cmd.map EnvNavMsg newMsg
            )

    EnvSelectionMsg subMsg ->
      case EnvSelection.update subMsg model.selectedEnvModel of
        (newSelectedEnvModel, newMsg) ->
          ( { model | selectedEnvModel = newSelectedEnvModel }, Cmd.map EnvSelectionMsg newMsg)

    PostmanMsg subMsg ->
      case Postman.update subMsg model.postmanModel of
        (Just newBuilderTree, newMsg) ->
          let
            newBuilderTreeModel =
              { selectedBuilderIndex = Nothing
              , displayedBuilderIndexes = []
              , tree = newBuilderTree
              , displayedNodeMenuIndex = Nothing
              }
          in
            ( { model | treeModel = newBuilderTreeModel }, Cmd.map PostmanMsg newMsg)

        (Nothing, newMsg) ->
          (model, Cmd.none)

    BuilderMsg subMsg ->
      let
        mBuilder = Debug.log "mbuilder" Maybe.andThen (BuilderTree.findBuilder model.treeModel.tree) model.treeModel.selectedBuilderIndex
      in
        case (subMsg, mBuilder) of
          (Builder.AskRun b, Just builder) ->
            let
              (updatedRequestRunner, cmdRequestRunner) = (RequestRunner.update (RequestRunner.Run model.envModel builder) model.runnerModel)
            in
              ( { model | runnerModel = updatedRequestRunner }, Cmd.map RequestRunnerMsg cmdRequestRunner)

          (_, Just builder) ->
            let
              (updatedBuilder, cmdBuilder) = (Builder.update subMsg builder)
            in
              (model, Cmd.map BuilderMsg cmdBuilder)

          _ ->
            (model, Cmd.none)
      {-
      let
        mUpdatedBuilderToCmd : Maybe (Builder.Model, Cmd Builder.Msg)
        mUpdatedBuilderToCmd = Maybe.map (Builder.update subMsg) (builders model.treeModel)
      in
        case (mBuilder model.treeModel, subMsg) of
          (Nothing, _) -> (model, Cmd.none)
          (Just builder, Builder.AskRun) ->
            let
              (updatedRequestRunner, cmdRequestRunner) = (RequestRunner.update (RequestRunner.Run model.envModel builder) model.runnerModel)
            in
              ( { model | runnerModel = updatedRequestRunner }, Cmd.map RequestRunnerMsg cmdRequestRunner)
          (Just builder, _) ->
            let
              (updatedBuilder, cmdBuilder) = (Builder.update subMsg builder)
            in
              (model, Cmd.map BuilderMsg cmdBuilder)
-}
    RequestRunnerMsg subMsg ->
      {-
      case (subMsg, mBuilder model.treeModel, model.treeModel.displayedBuilderIndexes) of
        (RequestRunner.GetResponse response, Just builder, builderIndexes) ->
          let
            (updatedBuilder, cmdBuilder) = (Builder.update (Builder.GiveResponse response) builder)
            updateNode : BuilderTree.Node -> BuilderTree.Node
            updateNode oldNode =
              case oldNode of
                BuilderTree.File { name } -> BuilderTree.File { name = name, builder = updatedBuilder, showRenameInput = False }
                _ -> oldNode
            newBuilderTree = BuilderTree.modifyNode updateNode model.treeModel.tree 1 --builderIdx
            oldBuilderTreeModel = model.treeModel
            newBuilderTreeModel = { oldBuilderTreeModel | tree = newBuilderTree }
          in
            ( { model | treeModel = newBuilderTreeModel }, Cmd.map BuilderMsg cmdBuilder)
        _ -> (model, Cmd.none)-}
      (model, Cmd.none)

    EnvMsg subMsg ->
      case Env.update subMsg model.envModel of
        (newEnv, newMsg) ->
          ( { model | envModel = newEnv }, Cmd.map EnvMsg newMsg)

    MainNavBarMsg subMsg ->
        case MainNavBar.update subMsg model.mainNavBarModel of
            (newMainNavBarModel, newMsg) ->
                ( { model | mainNavBarModel = newMainNavBarModel }
                , Cmd.map MainNavBarMsg newMsg
                )

    VarAppMsg subMsg ->
        case VarApp.update subMsg model.varAppModel of
            (newVarAppModel, newMsg) ->
                ( { model | varAppModel = newVarAppModel }
                , Cmd.map VarAppMsg newMsg
                )

    BuildersMsg subMsg ->
      case subMsg of
        Builders.BuilderMsg (Builder.AskRun builder) ->
          case EnvNav.getSelectedEnvInfo model.envNavModel of
            Just envInfo ->
              case RequestRunner.update (RequestRunner.Run envInfo.env builder) Nothing of
                (_, runnerSubMsg) -> (model, Cmd.map RequestRunnerMsg runnerSubMsg)

            Nothing ->
              (model, Cmd.none)
        _ ->
          case Builders.update subMsg model.treeModel of
            (newBuilderTree, newMsg) ->
              ( { model | treeModel = newBuilderTree }, sendSaveTabRequest newBuilderTree)

    SaveBuilderTreeResponse foo ->
      (model, Cmd.none)

builders : BuilderTree.Model -> List (Maybe Builder.Model)
builders treeModel = List.map (BuilderTree.findBuilder treeModel.tree) treeModel.displayedBuilderIndexes

subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.none
