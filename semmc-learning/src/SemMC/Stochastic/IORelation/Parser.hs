{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeOperators #-}
module SemMC.Stochastic.IORelation.Parser (
  readIORelation,
  printIORelation
  ) where

import           Control.Applicative
import qualified Control.Monad.Catch as E
import           Data.Proxy ( Proxy(..) )
import qualified Data.SCargot as SC
import qualified Data.SCargot.Repr as SC
import qualified Data.Set as S
import qualified Data.Text as T
import qualified Text.Parsec as P
import qualified Text.Parsec.Text as P
import           Text.Read ( readMaybe )

import qualified Data.Parameterized.HasRepr as HR
import           Data.Parameterized.Some ( Some(..) )
import qualified Data.Parameterized.List as SL

import qualified Data.Parameterized.Unfold as U
import qualified SemMC.Architecture as A
import qualified SemMC.Architecture.Concrete as AC
import           SemMC.Stochastic.IORelation.Types

{-

The format is expected to be a simple s-expression recording inputs and outputs

((inputs ((implicit . rax) (operand . 0)))
 (outputs ()))

-}

data Atom = AIdent String
          | AWord Word
          deriving (Show)

parseIdent :: P.Parser String
parseIdent = do
  l1 <- P.letter
  ls <- P.many (P.try P.alphaNum <|> P.oneOf "[]:")
  return (l1 : ls)

parseWord :: P.Parser Word
parseWord = do
  mw <- P.many1 P.digit
  case readMaybe mw of
    Just w -> return w
    Nothing -> fail "Invalid word"

parseAtom :: P.Parser Atom
parseAtom = AIdent <$> parseIdent
        <|> AWord <$> parseWord

parserLL :: SC.SExprParser Atom (SC.SExpr Atom)
parserLL = SC.mkParser parseAtom

parseLL :: T.Text -> Either String (SC.SExpr Atom)
parseLL = SC.decodeOne parserLL

printIORelation :: forall arch sh . (AC.ConcreteArchitecture arch) => IORelation arch sh -> T.Text
printIORelation = SC.encodeOne (SC.basicPrint printAtom) . (fromIORelation (Proxy @arch))

printAtom :: Atom -> T.Text
printAtom a =
  case a of
    AIdent s -> T.pack s
    AWord w -> T.pack (show w)

fromIORelation :: (AC.ConcreteArchitecture arch) => Proxy arch -> IORelation arch sh -> SC.SExpr Atom
fromIORelation p ior =
  SC.SCons (SC.SCons (SC.SAtom (AIdent "inputs")) inputsS)
           (SC.SCons (SC.SCons (SC.SAtom (AIdent "outputs")) outputsS)
                      SC.SNil)
  where
    inputsS = fromList (map toSExpr (S.toList (inputs ior)))
    outputsS = fromList (map toSExpr (S.toList (outputs ior)))

    fromList = foldr SC.SCons SC.SNil

    toSExpr rel =
      case rel of
        ImplicitOperand (Some loc) -> SC.SCons (SC.SAtom (AIdent "implicit")) (SC.SAtom (AIdent (AC.showView loc)))
        OperandRef (Some ix) -> SC.SCons (SC.SAtom (AIdent "operand")) (SC.SAtom (AWord (indexToWord p ix)))

indexToWord :: Proxy arch -> SL.Index sh s -> Word
indexToWord p ix =
  case ix of
    SL.IndexHere -> 0
    SL.IndexThere ix' -> 1 + indexToWord p ix'

data IORelationParseError arch = IORelationParseError (Proxy arch) (Some (A.Opcode arch (A.Operand arch))) T.Text
                               | InvalidSExpr (Proxy arch) (Some (A.Opcode arch (A.Operand arch))) (SC.SExpr Atom)
                               | InvalidLocation (Proxy arch) String
                               | InvalidIndex (Proxy arch) (Some (A.Opcode arch (A.Operand arch))) Word

deriving instance (A.Architecture arch) => Show (IORelationParseError arch)
instance (A.Architecture arch) => E.Exception (IORelationParseError arch)

readIORelation :: forall arch m sh
                . (E.MonadThrow m,
                   AC.ConcreteArchitecture arch,
                   A.ArchRepr arch)
               => Proxy arch
               -> T.Text
               -> A.Opcode arch (A.Operand arch) sh
               -> m (IORelation arch sh)
readIORelation p t op = do
  sx <- case parseLL t of
    Left _err -> E.throwM (IORelationParseError p (Some op) t)
    Right res -> return res
  (inputsS, outputsS) <- case sx of
    SC.SCons (SC.SCons (SC.SAtom (AIdent "inputs")) inputsS)
             (SC.SCons (SC.SCons (SC.SAtom (AIdent "outputs")) outputsS)
                        SC.SNil) -> return (inputsS, outputsS)
    _ -> E.throwM (InvalidSExpr p (Some op) sx)
  ins <- parseRelationList p op inputsS
  outs <- parseRelationList p op outputsS
  return IORelation { inputs = S.fromList ins, outputs = S.fromList outs }

parseRelationList :: forall m sh arch
                   . (E.MonadThrow m,
                      AC.ConcreteArchitecture arch,
                      A.ArchRepr arch)
                  => Proxy arch
                  -> A.Opcode arch (A.Operand arch) sh
                  -> SC.SExpr Atom
                  -> m [OperandRef arch sh]
parseRelationList proxy opcode s0 =
  case s0 of
    SC.SNil -> return []
    SC.SCons (SC.SCons (SC.SAtom (AIdent "implicit")) (SC.SAtom (AIdent loc))) rest -> do
      rest' <- parseRelationList proxy opcode rest
      case AC.readView loc of
        Nothing -> E.throwM (InvalidLocation proxy loc)
        Just sloc -> return (ImplicitOperand sloc : rest')
    SC.SCons (SC.SCons (SC.SAtom (AIdent "operand")) (SC.SAtom (AWord ix))) rest -> do
      rest' <- parseRelationList proxy opcode rest
      oref <- mkOperandRef proxy opcode ix
      return (oref : rest')
    _ -> E.throwM (InvalidSExpr proxy (Some opcode) s0)

-- | Take an integer and try to construct a `D.Index` that points at the
-- appropriate index into the operand list of the given opcode.
--
-- This involves traversing the type level operand list via 'U.unfoldShape'
mkOperandRef :: forall m arch sh
              . (E.MonadThrow m,
                 A.Architecture arch,
                 A.ArchRepr arch)
             => Proxy arch
             -> A.Opcode arch (A.Operand arch) sh
             -> Word
             -> m (OperandRef arch sh)
mkOperandRef proxy op w0 = U.unfoldShape (HR.typeRepr op) nil elt w0
  where
    -- We got to the end of the type level list without finding our index, so it
    -- was out of bounds
    nil :: Word -> m (OperandRef arch '[])
    nil _ = E.throwM (InvalidIndex proxy (Some op) w0)

    elt :: forall tp tps' tps . (tps ~ (tp ': tps')) => A.OperandTypeRepr arch  tp -> A.ShapeRepr arch tps' -> Word -> m (OperandRef arch tps)
    elt _ reps w =
      case w of
        0 -> return (OperandRef (Some SL.IndexHere))
        _ -> do
          shape <- U.unfoldShape reps nil elt (w - 1)
          case shape of
            OperandRef (Some ix) -> return (OperandRef (Some (SL.IndexThere ix)))
            ImplicitOperand _ -> error "Invalid shape for mkOperandRef"
