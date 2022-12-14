module Foreign.Hooks (useResizeObserver, UseResizeObserver(..), useContentBox) where

import Prelude

import Data.Foldable as Foldable
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.Nullable (Nullable)
import Effect (Effect)
import Effect.Aff (Milliseconds(..))
import Effect.Aff as Aff
import Effect.Class as Effect
import Effect.Uncurried (EffectFn1)
import Effect.Uncurried as Uncurried
import React.Basic (Ref)
import React.Basic.Hooks (type (&), Hook, Render, UseLayoutEffect, UseState, (/\))
import React.Basic.Hooks as Hooks
import React.Basic.Hooks.Aff (UseAff)
import React.Basic.Hooks.Aff as Hooks.Aff
import Web.DOM.Element as Element
import Web.DOM.Node (Node)

newtype UseResizeObserver hooks = UseUseResizeObserver hooks

derive instance Newtype (UseResizeObserver hooks) _

useContentBox
  :: forall hooks
   . Ref (Nullable Node)
  -> Render hooks
       ( hooks
           & UseState (Maybe { width :: Number, height :: Number })
           & UseState (Maybe { width :: Number, height :: Number })
           & UseLayoutEffect Unit
           & UseResizeObserver
           & UseAff (Maybe { width :: Number, height :: Number }) Unit
       )
       (Maybe { width :: Number, height :: Number })
useContentBox ref = Hooks.do
  box /\ setBox <- Hooks.useState' Nothing

  debouncedBox /\ setDebouncedBox <- Hooks.useState' Nothing

  Hooks.useLayoutEffectOnce do
    maybeElement <- Hooks.readRefMaybe ref
    Foldable.for_ (maybeElement >>= Element.fromNode) \element -> do
      rect <- Element.getBoundingClientRect element
      setBox (Just { width: rect.width, height: rect.height })
    pure mempty
  useResizeObserver ref \box' -> setBox (Just box')

  Hooks.Aff.useAff box do
    Aff.delay (200.0 # Milliseconds)
    Effect.liftEffect (setDebouncedBox box)

  pure debouncedBox

useResizeObserver
  :: Ref (Nullable Node)
  -> ({ width :: Number, height :: Number } -> Effect Unit)
  -> Hook UseResizeObserver Unit
useResizeObserver ref callback =
  Hooks.unsafeHook
    ( Uncurried.runEffectFn1
        _useResizeObserver
        { ref
        , callback: Uncurried.mkEffectFn1 callback
        }
    )

foreign import _useResizeObserver
  :: EffectFn1
       { ref :: Ref (Nullable Node)
       , callback :: EffectFn1 { width :: Number, height :: Number } Unit
       }
       Unit