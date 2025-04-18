--------------------------------------------------------------------------------
module Language.Haskell.Stylish.Step.UnicodeSyntax
    ( step
    ) where


--------------------------------------------------------------------------------
import qualified GHC.Hs                                        as GHC
import qualified GHC.Types.SrcLoc                              as GHC


--------------------------------------------------------------------------------
import qualified Language.Haskell.Stylish.Editor               as Editor
import           Language.Haskell.Stylish.Module
import           Language.Haskell.Stylish.Step
import           Language.Haskell.Stylish.Step.LanguagePragmas (addLanguagePragma)
import           Language.Haskell.Stylish.Util                 (everything)


--------------------------------------------------------------------------------
hsTyReplacements :: GHC.HsType GHC.GhcPs -> Editor.Edits
hsTyReplacements (GHC.HsFunTy _ arr _ _)
    | GHC.HsUnrestrictedArrow (GHC.EpUniTok epaLoc GHC.NormalSyntax) <- arr =
        Editor.replaceRealSrcSpan (GHC.epaLocationRealSrcSpan epaLoc) "→"
hsTyReplacements (GHC.HsQualTy _ ctx _)
    | Just arrow <- GHC.ac_darrow . GHC.anns $ GHC.getLoc ctx
    , (GHC.NormalSyntax, GHC.EpaSpan (GHC.RealSrcSpan loc _)) <- arrow =
        Editor.replaceRealSrcSpan loc "⇒"
hsTyReplacements _ = mempty


--------------------------------------------------------------------------------
hsSigReplacements :: GHC.Sig GHC.GhcPs -> Editor.Edits
hsSigReplacements (GHC.TypeSig ann _ _)
    | GHC.AddEpAnn GHC.AnnDcolon epaLoc <- GHC.asDcolon ann
    , GHC.EpaSpan (GHC.RealSrcSpan loc _) <- epaLoc =
        Editor.replaceRealSrcSpan loc "∷"
hsSigReplacements _ = mempty


--------------------------------------------------------------------------------
step :: Bool -> String -> Step
step = (makeStep "UnicodeSyntax" .) . step'


--------------------------------------------------------------------------------
step' :: Bool -> String -> Lines -> Module -> Lines
step' alp lg ls modu = Editor.apply edits ls
  where
    edits =
        foldMap hsTyReplacements (everything modu) <>
        foldMap hsSigReplacements (everything modu) <>
        (if alp then addLanguagePragma lg "UnicodeSyntax" modu else mempty)
