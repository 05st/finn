{-# OPTIONS_GHC -Wno-name-shadowing #-}

module CheckModules where

import qualified Data.Map as M
import qualified Data.Set as S

import Control.Arrow
import Control.Monad
import Control.Monad.Except
import Control.Monad.State

import AnalysisError
import Syntax hiding (FnDecl(nodeId))

type Check = ExceptT AnalysisError (State CheckState)
data CheckState = CheckState
    { edges :: M.Map Namespace [Import]
    , visited :: S.Set Namespace
    } deriving (Show)

checkModules :: BaseProgram -> Maybe AnalysisError
checkModules modules =
    case evalState (runExceptT (checkProgram modPaths)) (CheckState { edges = initEdges, visited = initVisited }) of
        Left err -> Just err
        _ -> Nothing
    where
        modPaths = map modPath modules
        initEdges = M.fromList (map (modPath &&& imports) modules)
        initVisited = S.empty

checkProgram :: [Namespace] -> Check ()
checkProgram [] = return ()
checkProgram (mod : mods) = do
    visiteds <- gets visited
    if S.notMember mod visiteds
        then dfs [] mod
        else checkProgram mods
    where
        visit m = modify (\s -> s { visited = S.insert m (visited s) })
        dfs cycle mod = do
            visit mod
            edgesMap <- gets edges
            visitedSet <- gets visited

            let modEdges = M.findWithDefault [] mod edgesMap
                modEdgesPaths = map importPath modEdges
                undefinedImports = filter ((`S.notMember` M.keysSet edgesMap) . importPath) modEdges

            unless (null undefinedImports) -- Verify imported modules exist
                $ throwError (UndefinedModulesError undefinedImports)

            when (any (`S.member` visitedSet) modEdgesPaths) -- Check for any cycles
                $ throwError (CyclicDependencyError (map showNamespace (reverse (mod : cycle))))
            
            mapM_ (dfs (mod : cycle)) modEdgesPaths
