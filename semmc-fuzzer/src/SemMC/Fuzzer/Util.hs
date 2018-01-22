{-# LANGUAGE GADTs #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE FlexibleContexts #-}
module SemMC.Fuzzer.Util
  ( stateDiff
  , statePairs
  , makePlain
  )
where

import qualified Data.Set as S
import           Data.Maybe (catMaybes)

import           Data.Parameterized.Some (Some(..))
import qualified Data.Parameterized.Map as MapF
import qualified Data.Word.Indexed as W

import qualified SemMC.Formula as F
import qualified SemMC.Architecture as A
import qualified SemMC.Architecture.View as V
import qualified SemMC.Architecture.Value as V
import           SemMC.Synthesis.Template ( BaseSet, TemplatedArch
                                          , unTemplate
                                          )

statePairs :: (A.Architecture arch, MapF.ShowF (A.Location arch))
          => proxy arch
          -> V.ConcreteState arch
          -> [(String, String)]
statePairs _ s =
    let showValue (V.ValueBV v) = show $ W.unW v
        showValue other = show other
    in [ (MapF.showF k, showValue v) | MapF.Pair k v <- MapF.toList s ]

stateDiff :: (A.Architecture arch)
          => proxy arch
          -> V.ConcreteState arch
          -> V.ConcreteState arch
          -> [(Some (A.Location arch), (Maybe (Some V.Value), Maybe (Some V.Value)))]
stateDiff _ a b =
    let aKeys = S.fromList $ MapF.keys a
        bKeys = S.fromList $ MapF.keys b
        allKeys = S.union aKeys bKeys
        pairs = [ (k,) <$>
                  case k of
                    Some v ->
                      let aVal = MapF.lookup v a
                          bVal = MapF.lookup v b
                      in if aVal == bVal
                         then Nothing
                         else Just (Some <$> aVal, Some <$> bVal)
                | k <- S.toList allKeys
                ]
    in catMaybes pairs

makePlain :: forall arch sym
           . (MapF.OrdF (A.Opcode arch (A.Operand arch)),
              MapF.OrdF (A.Location arch))
          => BaseSet sym arch
          -> MapF.MapF (A.Opcode arch (A.Operand arch)) (F.ParameterizedFormula sym arch)
makePlain = MapF.foldrWithKey f MapF.empty
  where f :: forall sh
           . A.Opcode arch (A.Operand arch) sh
          -> F.ParameterizedFormula sym (TemplatedArch arch) sh
          -> MapF.MapF (A.Opcode arch (A.Operand arch)) (F.ParameterizedFormula sym arch)
          -> MapF.MapF (A.Opcode arch (A.Operand arch)) (F.ParameterizedFormula sym arch)
        f op pf = MapF.insert op (unTemplate pf)
