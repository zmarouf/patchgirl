module EnvApp.EnvNav.App exposing (..)

import List.Extra as List

import EnvApp.EnvNav.Model exposing (..)
import EnvApp.EnvNav.Message exposing (Msg(..))

import EnvApp.App as EnvApp

update : Msg -> Model -> Model
update msg model =
  case msg of
    Select idx ->
      { model | selectedEnvIndex = Just idx }

    Delete idx ->
      let
        newEnvs = List.removeAt idx model.envs
        newSelectedEnvIndex =
          case model.selectedEnvIndex == Just idx of
            True -> Nothing
            False -> model.selectedEnvIndex

        newModel = { model | selectedEnvIndex = Debug.log "sindex" newSelectedEnvIndex
                   , envs = newEnvs }
      in
        newModel

    Add ->
      { model | envs = model.envs ++ [ defaultEnvInfo ] }

    ShowRenameInput idx ->
      { model | renameEnvIdx = Just idx }

    Rename idx newName ->
      let
        updateEnv old = { old | name = newName }
        mNewEnvs = List.updateAt idx updateEnv model.envs
      in
        case mNewEnvs of
          newEnvs ->
              { model | renameEnvIdx = Nothing, envs = newEnvs }


    EnvAppMsg idx subMsg ->
      case List.getAt idx model.envs of
        Nothing ->
            model
        Just { name, env } ->
          case EnvApp.update subMsg env of
            newEnvApp ->
              let
                newEnvApps = List.setAt idx { name = name, env = newEnvApp } model.envs
              in
                { model | envs = newEnvApps }
