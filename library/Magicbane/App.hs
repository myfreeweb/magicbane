{-# OPTIONS_GHC -fno-warn-missing-signatures #-}
{-# LANGUAGE NoMonomorphismRestriction, UnicodeSyntax, DataKinds, TypeOperators, MultiParamTypeClasses, TypeFamilies, FlexibleContexts, FlexibleInstances, UndecidableInstances, GeneralizedNewtypeDeriving, CPP #-}

-- | Extends Servant with context.
--   Basically wrapping Servant in a ReaderT of your type.
--   Which should be a tuple of all your moudles and configs and stuff, so that the Data.Has module would let you access these items by type.
module Magicbane.App (
  module X
, module Magicbane.App
) where

import           Control.Monad.Trans.Except as X
import           Control.Monad.Error.Class as X (MonadError, throwError)
import           Data.Proxy as X
import           Data.Has as X
import           Servant as X hiding (And)
-- replacing ClassyPrelude
import           Control.Exception.Safe hiding (Handler)
import           Control.Monad.Base
import           Control.Monad.IO.Class
import           Control.Monad.Reader
import           Control.Monad.Trans.Control

newtype MagicbaneApp β α = MagicbaneApp {
  unMagicbaneApp ∷ ReaderT β Handler α
} deriving (Functor, Applicative, Monad, MonadIO, MonadBase IO,
            MonadThrow, MonadCatch, MonadError ServantErr, MonadReader β)

instance MonadBaseControl IO (MagicbaneApp β) where
  type StM (MagicbaneApp β) α = StM (ReaderT β Handler) α
  liftBaseWith f = MagicbaneApp $ liftBaseWith $ \x → f $ x . unMagicbaneApp
  restoreM       = MagicbaneApp . restoreM

runMagicbaneHandler ∷ β → MagicbaneApp β α → Handler α
runMagicbaneHandler ctx a = Handler $ ExceptT $ liftIO $ runHandler $ runReaderT (unMagicbaneApp a) ctx

#if MIN_VERSION_servant_server(0,12,0)
#else
magicbaneToHandler ∷ β → MagicbaneApp β :~> Handler
#if MIN_VERSION_servant_server(0,10,0)
magicbaneToHandler ctx = NT $ runMagicbaneHandler ctx
#else
magicbaneToHandler ctx = Nat $ runMagicbaneHandler ctx
#endif
#endif

-- | Constructs a WAI application from an API definition, a Servant context (used for auth mainly), the app context and the actual action handlers.
magicbaneApp api sctx ctx actions = serveWithContext api sctx $ srv ctx
#if MIN_VERSION_servant_server(0,12,0)
  where srv c = hoistServer api (runMagicbaneHandler c) actions
#else
  where srv c = enter (magicbaneToHandler c) actions
#endif

-- | Gets a value of any type from the context.
askObj ∷ (Has β α, MonadReader α μ) ⇒ μ β
askObj = asks getter

-- | Gets a thing from a value of any type from the context. (Useful for configuration fields.)
askOpt ∷ (Has β α, MonadReader α μ) ⇒ (β → ψ) → μ ψ
askOpt f = asks $ f . getter
