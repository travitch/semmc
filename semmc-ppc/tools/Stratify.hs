{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE TypeApplications #-}
module Main ( main ) where

import qualified Control.Concurrent as C
import qualified Control.Concurrent.Async as A
import           Control.Monad ( when )
import           Data.Monoid
import           Data.Proxy ( Proxy(..) )
import qualified Data.Constraint as C
import qualified Options.Applicative as O
import qualified System.Directory as DIR
import qualified System.Exit as IO
import qualified System.IO as IO
import           Text.Printf ( printf )

import qualified Data.Parameterized.Nonce as N
import           Data.Parameterized.Some ( Some(..) )
import           Data.Parameterized.Witness ( Witness(..) )

import qualified Lang.Crucible.Solver.SimpleBackend as SB

import qualified Dismantle.Arbitrary as DA
import qualified Dismantle.PPC as PPC
import           Dismantle.PPC.Random ()
import qualified SemMC.Concrete.State as CS
import qualified SemMC.Concrete.Execution as CE
import qualified SemMC.Constraints as C
import qualified SemMC.Log as L
import qualified SemMC.Formula as F
import qualified SemMC.Stochastic.IORelation as IOR
import qualified SemMC.Stochastic.Strata as SST

import qualified SemMC.Architecture.PPC as PPC

import qualified Logging as L
import qualified OpcodeLists as OL
import qualified Util as Util

data Logging = Verbose | Quiet

data Options = Options { oRelDir :: FilePath
                       , oBaseDir :: FilePath
                       , oPseudoDir :: FilePath
                       , oLearnedDir :: FilePath
                       , oStatisticsFile :: FilePath
                       , oProgramCount :: Int
                       , oRandomTests :: Int
                       , oNumThreads :: Int
                       , oOpcodeTimeoutSeconds :: Int
                       , oRemoteTimeoutSeconds :: Int
                       , oRemoteHost :: String
                       , oPrintLog :: Logging
                       }

optionsParser :: O.Parser Options
optionsParser = Options <$> O.strOption ( O.long "relation-directory"
                                        <> O.short 'r'
                                        <> O.metavar "DIR"
                                        <> O.help "The directory to store learned IO relations" )
                        <*> O.strOption ( O.long "base-directory"
                                        <> O.short 'b'
                                        <> O.metavar "DIR"
                                        <> O.help "The directory to find the base set of semantics" )
                        <*> O.strOption ( O.long "pseudo-directory"
                                        <> O.short 'p'
                                        <> O.metavar "DIR"
                                        <> O.help "The directory to find the pseudo ops" )
                        <*> O.strOption ( O.long "learned-directory"
                                        <> O.short 'l'
                                        <> O.metavar "DIR"
                                        <> O.help "The directory to store learned semantics" )
                        <*> O.strOption ( O.long "statistics-file"
                                        <> O.short 's'
                                        <> O.metavar "FILE"
                                        <> O.help "The file in which to persist search statistics" )
                        <*> O.option O.auto ( O.long "program-threshold"
                                            <> O.short 'P'
                                            <> O.value 10
                                            <> O.showDefault
                                            <> O.metavar "COUNT"
                                            <> O.help "The number of candidate programs to find before extracting a formula" )
                        <*> O.option O.auto ( O.long "random-test-count"
                                            <> O.short 'R'
                                            <> O.metavar "COUNT"
                                            <> O.value 1000
                                            <> O.showDefault
                                            <> O.help "The number of random test vectors to generate" )
                        <*> O.option O.auto ( O.long "num-threads"
                                            <> O.short 'N'
                                            <> O.metavar "THREADS"
                                            <> O.help "The number of executor threads to run" )
                        <*> O.option O.auto (  O.long "opcode-timeout"
                                            <> O.short 't'
                                            <> O.metavar "SECONDS"
                                            <> O.value 1200
                                            <> O.showDefault
                                            <> O.help "The number of seconds to wait before giving up on learning a program for an opcode" )
                        <*> O.option O.auto ( O.long "remote-timeout"
                                            <> O.short 'T'
                                            <> O.metavar "SECONDS"
                                            <> O.help "The number of seconds to wait for all responses from the remote runner" )
                        <*> O.strOption ( O.long "remote-host"
                                        <> O.short 'H'
                                        <> O.metavar "HOST"
                                        <> O.help "The host to run the remote work on" )
                        <*> O.flag Quiet Verbose ( O.long "verbose"
                                                 <> O.short 'V'
                                                 <> O.help "Print log messages from the remote runner" )

main :: IO ()
main = O.execParser optParser >>= mainWithOptions
 where
   optParser = O.info (optionsParser O.<**> O.helper)
     ( O.fullDesc
     <> O.progDesc "Learn semantics for PPC instructions"
     <> O.header "semmc-ppc-stratify - learn semantics for each instruction")

die :: String -> IO a
die msg = IO.hPutStr IO.stderr msg >> IO.exitFailure

mainWithOptions :: Options -> IO ()
mainWithOptions opts = do
  when (oNumThreads opts < 1) $ do
    die $ printf "Invalid thread count: %d\n" (oNumThreads opts)

  iorels <- IOR.loadIORelations (Proxy @PPC.PPC) (oRelDir opts) Util.toIORelFP (C.weakenConstraints (C.Sub C.Dict) OL.allOpcodes)

  rng <- DA.createGen
  let testGenerator = CS.randomState (Proxy @PPC.PPC) rng
  Some ng <- N.newIONonceGenerator
  sym <- SB.newSimpleBackend ng
  let serializer = CE.TestSerializer { CE.flattenMachineState = CS.serialize (Proxy @PPC.PPC)
                                     , CE.parseMachineState = CS.deserialize (Proxy @PPC.PPC)
                                     , CE.flattenProgram = mconcat . map PPC.assembleInstruction
                                     }

  logChan <- C.newChan
  logger <- case oPrintLog opts of
    Verbose -> A.async (L.printLogMessages logChan)
    Quiet -> A.async (L.dumpLog logChan)
  A.link logger
  lcfg <- L.mkLogCfg
  logThread <- A.async (L.stdErrLogEventConsumer lcfg)
  A.link logThread

  DIR.createDirectoryIfMissing True (oLearnedDir opts)
  let cfg = SST.Config { SST.baseSetDir = oBaseDir opts
                       , SST.pseudoSetDir = oPseudoDir opts
                       , SST.learnedSetDir = oLearnedDir opts
                       , SST.statisticsFile = oStatisticsFile opts
                       , SST.programCountThreshold = oProgramCount opts
                       , SST.randomTestCount = oRandomTests opts
                       , SST.remoteRunnerTimeoutSeconds = oRemoteTimeoutSeconds opts
                       , SST.opcodeTimeoutSeconds = oOpcodeTimeoutSeconds opts
                       , SST.threadCount = oNumThreads opts
                       , SST.testRunner = CE.runRemote (oRemoteHost opts) serializer
                       , SST.logChannel = logChan
                       , SST.logConfig = lcfg
                       }
  let opcodes :: [Some (Witness (F.BuildOperandList PPC.PPC) (PPC.Opcode PPC.Operand))]
      opcodes = C.weakenConstraints (C.Sub C.Dict) OL.allOpcodes
  senv <- SST.loadInitialState cfg sym testGenerator initialTestCases opcodes OL.pseudoOps opcodes iorels
  _ <- SST.stratifiedSynthesis senv
  return ()
  where
    initialTestCases = CS.heuristicallyInterestingStates (Proxy @PPC.PPC)