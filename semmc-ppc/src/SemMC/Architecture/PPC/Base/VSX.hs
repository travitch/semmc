{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ImplicitParams #-}
-- | Semantics for the Vector Scalar Extensions (VSX)
--
-- This extends the number of vector registers to 64, of which 32 alias the
-- AltiVec registers.  They are still 128 bits.
module SemMC.Architecture.PPC.Base.VSX (
  baseVSX
  ) where

import Prelude hiding ( concat )
import Control.Monad ( when )
import SemMC.DSL
import SemMC.Architecture.PPC.Base.Core
import SemMC.Architecture.PPC.Base.FP

-- | Definitions of vector instructions
--
-- FIXME: For now, these are all stubs that leave their destination register as
-- undefined.
baseVSX :: (?bitSize :: BitSize) => SemM 'Top ()
baseVSX = do
  vsxLoad
  vsxStore
  vsxFloat
  vsxBitwise

vsxFloat :: (?bitSize :: BitSize) => SemM 'Top ()
vsxFloat = do
  defineOpcodeWithIP "XSABSDP" $ do
    comment "VSX Scalar Absolute Value Double-Precision (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSADDDP" $ do
    comment "VSX Scalar Add Double-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XADDSP" $ do
    comment "VSX Scalar Add Single-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSCMPODP" $ do
    comment "VSX Scalar Compare Ordered Double-Precision (XX3-form)"
    bf <- param "bf" crrc (EBV 3)
    xA <- param "xA" vsrc vectorBV
    xB <- param "xB" vsrc vectorBV
    input xA
    input xB
    input cr
    input bf
    defLoc cr (undefinedBV 32)

  defineOpcodeWithIP "XSCMPUDP" $ do
    comment "VSX Scalar Compare Unordered Double-Precision (XX3-form)"
    bf <- param "bf" crrc (EBV 3)
    xA <- param "xA" vsrc vectorBV
    xB <- param "xB" vsrc vectorBV
    input xA
    input xB
    input cr
    input bf
    defLoc cr (undefinedBV 32)

  defineOpcodeWithIP "XSCVDPSP" $ do
    comment "VSX Scalar Round Double-Precision to Single-Precision and Convert to Single-Precision Format (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSCVDPSPN" $ do
    comment "VSX Scalar Convert Scalar Single-Precision to Vector Single-Precision Format Non-Signaling (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSCVDPSXDS" $ do
    comment "VSX Scalar Truncate Double-Precision to Integer and Convert to Signed Integer Doubleword Format with Saturate (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSCVDPSXWS" $ do
    comment "VSX Scalar Truncate Double-Precision to Integer and Convert to Signed Integer Word Format with Saturate (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSCVDPUXDS" $ do
    comment "VSX Scalar Truncate Double-Precision Integer and Convert to Unsigned Integer Doubleword Format with Saturate (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSCVSPDP" $ do
    comment "VSX Scalar Convert Single-Precision to Double-Precision Format (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSCVSPDPN" $ do
    comment "VSX Scalar Convert Single-Precision to Double-Precision Format Non-signaling (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSCVSXDSP" $ do
    comment "VSX Scalar Convert Signed Integer Doubleword to Floating-Point Format and Round to Single-Precision (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSCVUXDDP" $ do
    comment "VSX Scalar Convert Unsigned Integer Doubleword to Floating-Point Format and Round to Double-Precision Format (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSCVUXDSP" $ do
    comment "VSX Scalar Convert Unsigned Integer Doubleword to Floating-Point Format and Round to Single-Precision (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSDIVDP" $ do
    comment "VSX Scalar Divide Double-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSDIVSP" $ do
    comment "VSX Scalar Divide Double-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSMADDADP" $ do
    comment "VSX Scalar Multiply-Add Double-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSMADDMDP" $ do
    comment "VSX Scalar Multiply-Add Double-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSMADDASP" $ do
    comment "VSX Scalar Multiply-Add Single-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSMADDMSP" $ do
    comment "VSX Scalar Multiply-Add Single-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSMAXDP" $ do
    comment "VSX Scalar Maximum Double-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSMINDP" $ do
    comment "VSX Scalar Minimum Double-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSMSUBADP" $ do
    comment "VSX Scalar Multiply-Subtract Double-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSMSUBMDP" $ do
    comment "VSX Scalar Multiply-Subtract Double-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSMSUBASP" $ do
    comment "VSX Scalar Multiply-Subtract Single-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSMSUBMSP" $ do
    comment "VSX Scalar Multiply-Subtract Single-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSMULDP" $ do
    comment "VSX Scalar Multiply Double-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSMULSP" $ do
    comment "VSX Scalar Multiply Single-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSNABSDP" $ do
    comment "VSX Scalar Negative Absolute Value Double-Precision (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSNEGDP" $ do
    comment "VSX Scalar Negate Double-Precision (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "VSNMADDADP" $ do
    comment "VSX Scalar Negative Multiply-Add Double-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "VSNMADDMDP" $ do
    comment "VSX Scalar Negative Multiply-Add Double-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "VSNMADDASP" $ do
    comment "VSX Scalar Negative Multiply-Add Single-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "VSNMADDMSP" $ do
    comment "VSX Scalar Negative Multiply-Add Single-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "VSNMSUBADP" $ do
    comment "VSX Scalar Negative Multiply-Subtract Double-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "VSNMSUBMDP" $ do
    comment "VSX Scalar Negative Multiply-Subtract Double-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "VSNMSUBASP" $ do
    comment "VSX Scalar Negative Multiply-Subtract Single-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "VSNMSUBMSP" $ do
    comment "VSX Scalar Negative Multiply-Subtract Single-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSRDPI" $ do
    comment "VSX Scalar Round to Double-Precision Integer using Round to Nearest Away (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSRDPIC" $ do
    comment "VSX Scalar Round to Double-Precision Integer Exact using Current Rounding Mode (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSRDPIM" $ do
    comment "VSX Scalar Round to Double-Precision Integer using Round Toward -Infinity (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSRDPIP" $ do
    comment "VSX Scalar Round to Double-Precision Integer using Round Toward +Infinity (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSRDPIZ" $ do
    comment "VSX Scalar Round to Double-Precision Integer using Round Toward Zero (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSREDP" $ do
    comment "VSX Scalar Reciprocal Estimate Double-Precision (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSREDP" $ do
    comment "VSX Scalar Reciprocal Estimate Single-Precision (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSRSQRTEDP" $ do
    comment "VSX Scalar Reciprocal Square Root Estimate Double-Precision (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSRSQRTESP" $ do
    comment "VSX Scalar Reciprocal Square Root Estimate Single-Precision (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSSQRTDP" $ do
    comment "VSX Scalar Square Root Estimate Double-Precision (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSSQRTSP" $ do
    comment "VSX Scalar Square Root Estimate Single-Precision (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSSUBDP" $ do
    comment "VSX Scalar Subtract Double-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSSUBSP" $ do
    comment "VSX Scalar Subtract Single-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XSTDIVDP" $ do
    comment "VSX Scalar Test for Software Divide Double-Precision (XX3-form)"
    bf <- param "bf" crrc (EBV 3)
    xA <- param "xA" vsrc vectorBV
    xB <- param "xB" vsrc vectorBV
    input bf
    input xA
    input xB
    input cr
    defLoc cr (undefinedBV 32)

  defineOpcodeWithIP "XSTSQRTDP" $ do
    comment "VSX Scalar Test for Software Square Root Double-Precision (XX2-form)"
    bf <- param "bf" crrc (EBV 3)
    xB <- param "xB" vsrc vectorBV
    input bf
    input xB
    input cr
    defLoc cr (undefinedBV 32)

  defineOpcodeWithIP "XVABSDP" $ do
    comment "VSX Vector Absolute Value Double-Precision (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XVABSSP" $ do
    comment "VSX Vector Absolute Value Single-Precision (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XVADDDP" $ do
    comment "VSX Vector Add Double-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XVADDSP" $ do
    comment "VSX Vector Add Single-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XVCMPEQDP" $ do
    comment "VSX Vector Compare Equal To Double-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)
    defineVRCVariant "XVCMPEQDPo" $ do
      comment "VSX Vector Compare Equal To Double-Precision & Record (XX3-form)"

  defineOpcodeWithIP "XVCMPEQSP" $ do
    comment "VSX Vector Compare Equal To Single-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)
    defineVRCVariant "XVCMPEQSPo" $ do
      comment "VSX Vector Compare Equal To Single-Precision & Record (XX3-form)"

  defineOpcodeWithIP "XVCMPGEDP" $ do
    comment "VSX Vector Compare Greater Than or Equal To Double-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)
    defineVRCVariant "XVCMPGEDPo" $ do
      comment "VSX Vector Compare Greater Than or Equal To Double-Precision & Record (XX3-form)"

  defineOpcodeWithIP "XVCMPGESP" $ do
    comment "VSX Vector Compare Greater Than or Equal To Single-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)
    defineVRCVariant "XVCMPGESPo" $ do
      comment "VSX Vector Compare Greater Than or Equal To Single-Precision & Record (XX3-form)"

  defineOpcodeWithIP "XVCMPGTDP" $ do
    comment "VSX Vector Compare Greater Than To Double-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)
    defineVRCVariant "XVCMPGTDPo" $ do
      comment "VSX Vector Compare Greater Than To Double-Precision & Record (XX3-form)"

  defineOpcodeWithIP "XVCMPGTSP" $ do
    comment "VSX Vector Compare Greater Than To Single-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)
    defineVRCVariant "XVCMPGTSPo" $ do
      comment "VSX Vector Compare Greater Than To Single-Precision & Record (XX3-form)"

  defineOpcodeWithIP "XVCPSGNDP" $ do
    comment "VSX Vector Copy Sign Double-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XVCPSGNSP" $ do
    comment "VSX Vector Copy Sign Single-Precision (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XVCVDPSP" $ do
    comment "VSX Vector Round Double-Precision to Single-Precision and Convert to Single-Precision Format (XX2-form)"
    (xT, _xB) <- xx2form
    defLoc xT (undefinedBV 128)

vsxBitwise :: (?bitSize :: BitSize) => SemM 'Top ()
vsxBitwise = do
  defineOpcodeWithIP "XXLAND" $ do
    comment "VSX Logical AND (XX3-form)"
    (xT, xA, xB) <- xx3form
    defLoc xT (bvand (Loc xA) (Loc xB))

  defineOpcodeWithIP "XXLANDC" $ do
    comment "VSX Logical AND with Complement (XX3-form)"
    (xT, xA, xB) <- xx3form
    defLoc xT (bvand (Loc xA) (bvnot (Loc xB)))

  defineOpcodeWithIP "XXLEQV" $ do
    comment "VSX Logical Equivalence (XX3-form)"
    (xT, xA, xB) <- xx3form
    defLoc xT (bvnot (bvxor (Loc xA) (Loc xB)))

  defineOpcodeWithIP "XXLNAND" $ do
    comment "VSX Logical NAND (XX3-form)"
    (xT, xA, xB) <- xx3form
    defLoc xT (bvnot (bvand (Loc xA) (Loc xB)))

  defineOpcodeWithIP "XXLORC" $ do
    comment "VSX Logical OR with Complement (XX3-form)"
    (xT, xA, xB) <- xx3form
    defLoc xT (bvor (Loc xA) (bvnot (Loc xB)))

  defineOpcodeWithIP "XXLNOR" $ do
    comment "VSX Logical NOR (XX3-form)"
    (xT, xA, xB) <- xx3form
    defLoc xT (bvnot (bvor (Loc xA) (Loc xB)))

  defineOpcodeWithIP "XXLOR" $ do
    comment "VSX Logical OR (XX3-form)"
    (xT, xA, xB) <- xx3form
    defLoc xT (bvor (Loc xA) (Loc xB))

  defineOpcodeWithIP "XXLXOR" $ do
    comment "VSX Logical XOR (XX3-form)"
    (xT, xA, xB) <- xx3form
    defLoc xT (bvxor (Loc xA) (Loc xB))

  defineOpcodeWithIP "XXMRGHW" $ do
    comment "VSX Merge High Word (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XXMRGLW" $ do
    comment "VSX Merge Low Word (XX3-form)"
    (xT, _xA, _xB) <- xx3form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XXPERMDI" $ do
    comment "VSX Permute Doubleword Immediate (XX3-form)"
    xT <- param "xT" vsrc vectorBV
    dm <- param "DM" u2imm (EBV 2)
    xA <- param "xA" vsrc vectorBV
    xB <- param "xB" vsrc vectorBV
    input dm
    input xA
    input xB
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XXSEL" $ do
    comment "VSX Select (XX4-form)"
    (xT, _xA, _xB, _xC) <- xx4form
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XXSLDWI" $ do
    comment "VSX Shift Left Double by Word Immediate (XX3-form)"
    xT <- param "xT" vsrc vectorBV
    shw <- param "SHW" u2imm (EBV 2)
    xA <- param "xA" vsrc vectorBV
    xB <- param "xB" vsrc vectorBV
    input shw
    input xA
    input xB
    defLoc xT (undefinedBV 128)

  defineOpcodeWithIP "XXSPLTW" $ do
    comment "VSX Splat Word (XX2-form)"
    xT <- param "xT" vsrc vectorBV
    uim <- param "UIM" u2imm (EBV 2)
    xB <- param "xB" vsrc vectorBV
    input uim
    input xB
    defLoc xT (undefinedBV 128)

xx4form :: SemM 'Def (Location 'TBV, Location 'TBV, Location 'TBV, Location 'TBV)
xx4form = do
  xT <- param "xT" vsrc vectorBV
  xA <- param "xA" vsrc vectorBV
  xB <- param "xB" vsrc vectorBV
  xC <- param "xC" vsrc vectorBV
  input xA
  input xB
  input xC
  return (xT, xA, xB, xC)

xx3form :: SemM 'Def (Location 'TBV, Location 'TBV, Location 'TBV)
xx3form = do
  xT <- param "xT" vsrc vectorBV
  xA <- param "xA" vsrc vectorBV
  xB <- param "xB" vsrc vectorBV
  input xA
  input xB
  return (xT, xA, xB)

xx2form :: SemM 'Def (Location 'TBV, Location 'TBV)
xx2form = do
  xT <- param "xT" vsrc vectorBV
  xB <- param "xB" vsrc vectorBV
  input xB
  return (xT, xB)

xx1form :: (?bitSize :: BitSize) => SemM 'Def (Location 'TBV, Location 'TBV)
xx1form = do
  xT <- param "xT" vsrc vectorBV
  rA <- param "rA" gprc naturalBV
  input xT
  return (xT, rA)

effectiveAddress :: (?bitSize :: BitSize) => Location 'TMemRef -> Expr 'TBV
effectiveAddress memref =
  let rA = memrrBaseReg memref
      rB = memrrOffsetReg (Loc memref)
      b = ite (isR0 (Loc rA)) (naturalLitBV 0x0) (Loc rA)
  in (bvadd rB b)

storeForm :: SemM 'Def (Location 'TBV, Location 'TMemRef)
storeForm = do
  memref <- param "memref" memrr EMemRef
  xS <- param "xS" vsrc vectorBV
  input xS
  input memory
  input memref
  return (xS, memref)

vsxStore :: (?bitSize :: BitSize) => SemM 'Top ()
vsxStore = do
  defineOpcodeWithIP "STXSDX" $ do
    comment "Store VSX Scalar Doubleword Indexed (XX1-form)"
    (xS, memref) <- storeForm
    let ea = effectiveAddress memref
    defLoc memory (storeMem (Loc memory) ea 8 (highBits128 64 (Loc xS)))

  defineOpcodeWithIP "STXSIWX" $ do
    comment "Store VSX Scalar as Integer Word Indexed (XX1-form)"
    (xS, memref) <- storeForm
    let ea = effectiveAddress memref
    defLoc memory (storeMem (Loc memory) ea 4 (highBits128 32 (Loc xS)))

  defineOpcodeWithIP "STXSSPX" $ do
    comment "Store VSX Scalar Single-Precision Indexed (XX1-form)"
    (xS, memref) <- storeForm
    let ea = effectiveAddress memref
    defLoc memory (storeMem (Loc memory) ea 4 (froundsingle (highBits128 64 (Loc xS))))

  defineOpcodeWithIP "STXVD2X" $ do
    comment "Store VSX Vector Doubleword*2 Indexed (XX1-form)"
    (xS, memref) <- storeForm
    let ea = effectiveAddress memref
    defLoc memory (storeMem (Loc memory) ea 16 (Loc xS))

  defineOpcodeWithIP "STXVW4X" $ do
    comment "Store VSX Vector Word*4 Indexed (XX1-form)"
    (xS, memref) <- storeForm
    let ea = effectiveAddress memref
    defLoc memory (storeMem (Loc memory) ea 16 (Loc xS))

loadForm :: SemM 'Def (Location 'TBV, Location 'TMemRef)
loadForm = do
  xT <- param "xT" vsrc vectorBV
  memref <- param "memref" memrr EMemRef
  input memory
  input memref
  return (xT, memref)

vsxLoad :: (?bitSize :: BitSize) => SemM 'Top ()
vsxLoad = do
  when (?bitSize == Size64) $ do
    defineOpcodeWithIP "MTVSRD" $ do
      comment "Move To VSR Doubleword (XX1-form)"
      (xT, rA) <- xx1form
      defLoc xT (concat (Loc rA) (undefinedBV 64))

    defineOpcodeWithIP "MFVSRD" $ do
      comment "Move From VSR Doubleword (XX1-form)"
      rA <- param "rA" gprc naturalBV
      xS <- param "xS" vsrc vectorBV
      input xS
      defLoc rA (highBits128 64 (Loc xS))

  defineOpcodeWithIP "MTVSRWA" $ do
    comment "Move To VSR Word Algebraic (XX1-form)"
    (xT, rA) <- xx1form
    defLoc xT (concat (sext' 64 (lowBits' 32 (Loc rA))) (undefinedBV 64))

  defineOpcodeWithIP "MTVSRWZ" $ do
    comment "Move To VSR Word Zero (XX1-form)"
    (xT, rA) <- xx1form
    defLoc xT (concat (zext' 64 (lowBits' 32 (Loc rA))) (undefinedBV 64))

  defineOpcodeWithIP "MFVSRWZ" $ do
    comment "Move From VSR Word and Zero (XX1-form)"
    rA <- param "rA" gprc naturalBV
    xS <- param "xS" vsrc vectorBV
    defLoc rA (zext (highBits128 32 (Loc xS)))

  defineOpcodeWithIP "LXSDX" $ do
    comment "Load VSX Scalar Doubleword Indexed (XX1-form)"
    (xT, memref) <- loadForm
    let ea = effectiveAddress memref
    defLoc xT (concat (readMem (Loc memory) ea 8) (undefinedBV 64))

  defineOpcodeWithIP "LXSIWAX" $ do
    comment "Load VSX Scalar as Integer Word Algebraic Indexed (XX1-form)"
    (xT, memref) <- loadForm
    let ea = effectiveAddress memref
    defLoc xT (concat (sext' 64 (readMem (Loc memory) ea 4)) (undefinedBV 64))

  defineOpcodeWithIP "LXSIWZX" $ do
    comment "Load VSX Scalar as Integer Word and Zero Indexed (XX1-form)"
    (xT, memref) <- loadForm
    let ea = effectiveAddress memref
    defLoc xT (concat (zext' 64 (readMem (Loc memory) ea 4)) (undefinedBV 64))

  defineOpcodeWithIP "LXSSPX" $ do
    comment "Load VSX Scalar Single-Precision Indexed (XX1-form)"
    (xT, memref) <- loadForm
    let ea = effectiveAddress memref
    defLoc xT (concat (fsingletodouble (readMem (Loc memory) ea 4)) (undefinedBV 64))

  defineOpcodeWithIP "LXVD2X" $ do
    comment "Load VSX Vector Doubleword*2 Indexed (XX1-form)"
    (xT, memref) <- loadForm
    let ea = effectiveAddress memref
    defLoc xT (concat (readMem (Loc memory) ea 8) (readMem (Loc memory) (bvadd ea (naturalLitBV 0x8)) 8))

  defineOpcodeWithIP "LXVDSX" $ do
    comment "Load VSX Vector Doubleword & Splat Indexed (XX1-form)"
    (xT, memref) <- loadForm
    let ea = effectiveAddress memref
    let val = readMem (Loc memory) ea 8
    defLoc xT (concat val val)

  defineOpcodeWithIP "LXVW4X" $ do
    comment "Load VSX Vector Word*4 Indexed (XX1-form)"
    (xT, memref) <- loadForm
    let ea = effectiveAddress memref
    let w1 = readMem (Loc memory) ea 4
    let w2 = readMem (Loc memory) (bvadd ea (naturalLitBV 0x4)) 4
    let w3 = readMem (Loc memory) (bvadd ea (naturalLitBV 0x8)) 4
    let w4 = readMem (Loc memory) (bvadd ea (naturalLitBV 0x12)) 4
    defLoc xT (concat w1 (concat w2 (concat w3 w4)))
