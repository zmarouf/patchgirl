{-# LANGUAGE DeriveGeneric #-}

module Env(createEnv, Env(..), DBConfig(..), GithubConfig(..)) where

import           Data.Text (Text)
import           Dhall

createEnv :: (String -> IO ()) -> (String -> IO ()) -> IO Env
createEnv log httpRequest = do
  Config{..} <- input auto "./config.dhall"
  return $ Env { envPort = configPort
               , envAppKeyFilePath = configAppKeyFilePath
               , envDB = configDB
               , envGithub = configGithub
               , envLog = log
               , envHttpRequest = httpRequest
               }


-- * db


data DBConfig
  = DBConfig { dbPort     :: Natural
             , dbName     :: Text
             , dbUser     :: Text
             , dbPassword :: Text
             }
  deriving (Generic, Show)

instance FromDhall DBConfig


-- * github


data GithubConfig
  = GithubConfig { githubConfigClientId     :: Text
                 , githubConfigClientSecret :: Text
                 }
  deriving (Generic, Show)

instance FromDhall GithubConfig


-- * config


data Config
  = Config { configPort           :: Natural
           , configAppKeyFilePath :: String
           , configDB             :: DBConfig
           , configGithub         :: GithubConfig
           }
  deriving (Generic, Show)

instance FromDhall Config


-- * env


data Env
  = Env { envPort           :: Natural
        , envAppKeyFilePath :: String
        , envDB             :: DBConfig
        , envGithub         :: GithubConfig
        , envLog            :: String -> IO ()
        , envHttpRequest    :: String -> IO ()
        }
