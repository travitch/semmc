{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main ( main ) where

import qualified Control.Exception as X
import           Control.Monad (forM_)
import qualified Data.Map as Map
import qualified Data.Parameterized.Context as Ctx
import           Data.Parameterized.Nonce
import           Data.Parameterized.Some ( Some(..) )
import qualified Data.Text as T
import qualified Data.List as List
import qualified Lang.Crucible.Backend.Simple as CBS
import qualified Lang.Crucible.FunctionHandle as CFH
import qualified Language.ASL.Parser as AP
import qualified Language.ASL.Syntax as AS
import System.Exit (exitFailure)
import qualified System.IO as IO

import SemMC.ASL
import SemMC.ASL.Crucible
import SemMC.ASL.Translation
import SemMC.ASL.Translation.Preprocess
import SemMC.ASL.Signature

instsFilePath :: FilePath
instsFilePath = "test/insts.parsed"

defsFilePath :: FilePath
defsFilePath = "test/defs.parsed"


collectInstructions :: [AS.Instruction] -> [(T.Text, T.Text)]
collectInstructions aslInsts =
  List.concat $ map (\(AS.Instruction nm encs _ _) ->
                       map (\(AS.InstructionEncoding {AS.encName=encName}) ->
                              (nm, encName)) encs) aslInsts
  

--"aarch32_ADC_i_A" "aarch32_ADC_i_A1_A"
main :: IO ()
main = do
  (aslInsts, aslDefs) <- getASL
  putStrLn $ "Loaded " ++ show (length aslInsts) ++ " instructions and " ++ show (length aslDefs) ++ " definitions."
  --let instrs = [collectInstructions aslInsts !! 4]
  --let instrs = [("aarch32_REV_A","aarch32_REV_T2_A")]
  let instrs = [("aarch32_ADC_i_A","aarch32_ADC_i_T1_A")]
  
  forM_ instrs (\(instr, enc) -> runTranslation instr enc aslInsts aslDefs)

computeDefs :: [T.Text] -> IO ()
computeDefs defIn = do
  (_, aslDefs) <- getASL
  case computeDefinitions defIn aslDefs of
    Left err -> do
      putStrLn $ "Error computing ASL definitions: " ++ show err
      exitFailure
    Right defs -> do
      putStrLn $ "--------------------------------"
      putStrLn "Translating functions: "
      sigMap <- return $ defSignatures defs
      forM_ (Map.toList sigMap) $ \(fnName, _) -> putStrLn $ "  * " ++ show fnName
      forM_ (Map.toList sigMap) $ \(fnName, (Some sig, c)) -> do
        putStrLn $ show fnName ++ " definition:"
        processFunction fnName sig c defs
   

runTranslation :: T.Text -> T.Text -> [AS.Instruction] -> [AS.Definition] -> IO ()
runTranslation instr enc aslInsts aslDefs = do
  putStrLn $ "Computing instruction signature for: " ++ show instr ++ " " ++ show enc
  case computeInstructionSignature instr enc aslInsts aslDefs of
    Left err -> do
      putStrLn $ "Error computing instruction signature: " ++ show err
      exitFailure
    Right (Some (SomeProcedureSignature iSig), instStmts, sigMap) -> do
      putStrLn $ "Instruction signature:"
      print iSig
      --Just mySig <- return $ Map.lookup "Unreachable_0" sigMap
      --sigMap <- return $ Map.fromList [("Unreachable_0", mySig)]

      case computeDefinitions (Map.keys sigMap) aslDefs of
        Left err -> do
          putStrLn $ "Error computing ASL definitions: " ++ show err
          exitFailure
        Right defs -> do
          putStrLn $ "--------------------------------"
          putStrLn "Translating functions: "
          forM_ (Map.toList sigMap) $ \(fnName, _) -> putStrLn $ "  * " ++ show fnName
          forM_ (Map.toList sigMap) $ \(fnName, (Some sig, c)) -> do
            putStrLn $ show fnName ++ " definition:"
            processFunction fnName sig (callableStmts c) defs
          putStrLn $ "--------------------------------"
          putStrLn $ "Translating instruction: " ++ T.unpack instr ++ " " ++ T.unpack enc
          putStrLn $ (show iSig)
          processInstruction iSig instStmts defs
    _ -> error "Panic"

-- Debugging function for determining what syntactic forms
-- actually exist
queryASL :: (T.Text -> AS.Expr -> b -> b) ->
            (T.Text -> AS.LValExpr -> b -> b) ->
            (T.Text -> AS.Stmt -> b -> b) -> b -> IO b
queryASL f h g b = do
  (aslInsts, aslDefs) <- getASL
  return $ foldASL f h g aslDefs aslInsts b

getASL :: IO ([AS.Instruction], [AS.Definition])
getASL = do
  eAslDefs <- AP.parseAslDefsFile defsFilePath
  eAslInsts <- AP.parseAslInstsFile instsFilePath
  case (eAslInsts, eAslDefs) of
    (Left err, _) -> do
      putStrLn $ "Error loading ASL instructions: " ++ show err
      exitFailure
    (_, Left err) -> do
      putStrLn $ "Error loading ASL definitions: " ++ show err
      exitFailure
    (Right aslInsts', Right aslDefs') -> do
      return $ prepASL (aslInsts', aslDefs')

processInstruction :: ProcedureSignature globals init -> [AS.Stmt] -> Definitions arch -> IO ()
processInstruction pSig stmts defs = do
  handleAllocator <- CFH.newHandleAllocator
  p <- procedureToCrucible defs pSig handleAllocator stmts
  backend <- CBS.newSimpleBackend globalNonceGenerator
  let cfg :: SimulatorConfig (CBS.SimpleBackend GlobalNonceGenerator (CBS.Flags CBS.FloatIEEE))
        = SimulatorConfig { simOutputHandle = IO.stdout
                          , simHandleAllocator = handleAllocator
                          , simSym = backend
                          }
  symFn <- simulateProcedure cfg p
  return ()

processFunction :: T.Text -> SomeSignature ret -> [AS.Stmt] -> Definitions arch -> IO ()
processFunction fnName sig stmts defs =
  case sig of
    SomeFunctionSignature fSig -> do
      handleAllocator <- CFH.newHandleAllocator
      f <- functionToCrucible defs fSig handleAllocator stmts
      backend <- CBS.newSimpleBackend globalNonceGenerator
      let cfg :: SimulatorConfig (CBS.SimpleBackend GlobalNonceGenerator (CBS.Flags CBS.FloatIEEE))
            = SimulatorConfig { simOutputHandle = IO.stdout
                              , simHandleAllocator = handleAllocator
                              , simSym = backend
                              }
      symFn <- simulateFunction cfg f
      return ()
    SomeProcedureSignature pSig -> do
      handleAllocator <- CFH.newHandleAllocator
      p <- procedureToCrucible defs pSig handleAllocator stmts
      backend <- CBS.newSimpleBackend globalNonceGenerator
      let cfg :: SimulatorConfig (CBS.SimpleBackend GlobalNonceGenerator (CBS.Flags CBS.FloatIEEE))
            = SimulatorConfig { simOutputHandle = IO.stdout
                              , simHandleAllocator = handleAllocator
                              , simSym = backend
                              }
      symFn <- simulateProcedure cfg p
      return ()
