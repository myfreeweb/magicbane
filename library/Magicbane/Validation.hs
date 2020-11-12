{-# OPTIONS_GHC -fno-warn-orphans #-}
{-# LANGUAGE OverloadedStrings, UnicodeSyntax #-}

-- | This module used to integrate the refinement types from the Refined library with aeson.
-- | This integration is now included in Refined library (as of 0.4), but we keep the re-export for convenience.
module Magicbane.Validation (
  module Refined
) where

import           Refined