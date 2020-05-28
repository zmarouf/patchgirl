{-# LANGUAGE DataKinds                 #-}
{-# LANGUAGE DuplicateRecordFields     #-}
{-# LANGUAGE FlexibleContexts          #-}
{-# LANGUAGE FlexibleInstances         #-}
{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE TypeOperators             #-}

module Account.AppSpec where

import           Servant
import           Servant.Client   (ClientM, client)
import           Test.Hspec

import           Helper.App
import           PatchGirl.Client
import           PatchGirl.Server


-- * client


resetVisitorAccount :: ClientM ()
resetVisitorAccount =
  client (Proxy :: Proxy AccountApi)


-- * spec


spec :: Spec
spec =
  withClient (mkApp defaultEnv) $


-- ** reset visitor account


    describe "reset visitor account" $
      it "should returns 200" $ \clientEnv ->
        cleanDBAfter $ \_ -> do
          res <- try clientEnv resetVisitorAccount
          res `shouldBe` ()