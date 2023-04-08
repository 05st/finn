{-# OPTIONS_GHC -Wno-missing-pattern-synonym-signatures #-}

module Syntax where

import Data.Text (Text)
import qualified Data.IntMap as IM

import Error.Diagnose

import Type

-- Position (Int, Int) (Int, Int) FilePath
type PositionMap = IM.IntMap Position -- NodeId -> Position
type NodeId = Int

type BaseProgram = Program ()
type BaseModule = Module ()
type BaseDecl = Decl ()
type BaseExpr = Expr ()

type TypedProgram = Program Type
type TypedModule = Module Type
type TypedDecl = Decl Type
type TypedExpr = Expr Type

type Namespace = [Text]

type Program x = [Module x]

data Module x = Module
    { modPath :: Namespace
    , imports :: [Import]
    , exports :: [Export]
    , decls   :: [Decl x]
    } deriving (Show)

data Import = Import
    { nodeId     :: !NodeId
    , importPath :: Namespace
    } deriving (Show)

data Export
    = ExportDecl !NodeId Text
    | ExportMod  !NodeId Namespace
    deriving (Show)

-- FnDecl is parsed then desugared into a DLetDecl
type FnDeclBranch = ([Text], BaseExpr)
data FnDecl = FnDecl
    { nodeId   :: !NodeId
    , name     :: Text
    , annot    :: Maybe Type
    , branches :: [FnDeclBranch]
    } deriving (Show)

data Decl x
    = DTrait
    | DImpl
    | DLetDecl !NodeId Text (Maybe Type) (Expr x)
    deriving (Show)

data Expr x
    = ELit     !NodeId x Lit
    | EVar     !NodeId x Namespace Text
    | EApp     !NodeId x (Expr x) (Expr x)
    | ELambda  !NodeId x Text (Expr x)
    | ETypeAnn !NodeId x (Expr x) Type
    | ELetExpr !NodeId x Text (Expr x) (Expr x)
    | EIfExpr  !NodeId x (Expr x) (Expr x) (Expr x)
    | EMatch   !NodeId x (Expr x) [(Pattern, Expr x)]
    deriving (Show)

pattern BaseELit id l = ELit id () l
pattern BaseEVar id n = EVar id () [] n
pattern BaseEApp id f e = EApp id () f e
pattern BaseELambda id p e = ELambda id () p e
pattern BaseETypeAnn id t e = ETypeAnn id () t e
pattern BaseELetExpr id n e b = ELetExpr id () n e b
pattern BaseEIfExpr id c t f = EIfExpr id () c t f
pattern BaseEMatch id e bs = EMatch id () e bs

-- Helper functions
eBinOp :: NodeId -> Text -> BaseExpr -> BaseExpr -> BaseExpr
eBinOp nodeId o a b = BaseEApp nodeId (BaseEApp nodeId (BaseEVar nodeId o) a) b

eUnaOp :: NodeId -> Text -> BaseExpr -> BaseExpr
eUnaOp nodeId o a = BaseEApp nodeId (BaseEVar nodeId o) a

data Lit
    = LInt    Integer
    | LFloat  Double
    | LString Text
    | LChar   Char
    | LBool   Bool
    | LUnit
    deriving (Show)
    
data Pattern
    = PLit Lit
    | PVar Text
    | PWild
    deriving (Show)
    
data Assoc
    = ALeft
    | ARight
    | ANone
    | APrefix
    | APostfix
    deriving (Show)

data OperatorDef = OperatorDef
    { assoc :: Assoc
    , prec  :: Integer
    , oper  :: Text
    } deriving (Show)
