{-# OPTIONS --without-K --safe #-}

open import Categories.Category
open import Categories.Functor hiding (id)

module Categories.Diagram.Limit
  {o ℓ e} {o′ ℓ′ e′} {C : Category o ℓ e} {J : Category o′ ℓ′ e′} (F : Functor J C) where

private
  module C = Category C
  module J = Category J
open C
open HomReasoning
open Functor F

open import Level
open import Data.Product using (proj₂)

open import Categories.Diagram.Cone F renaming (Cone⇒ to _⇨_)
open import Categories.Object.Terminal as T hiding (up-to-iso; transport-by-iso)
open import Categories.Square C
open import Categories.Morphism C
open import Categories.Morphism Cones as MC using () renaming (_≅_ to _⇔_ ; _≃_ to _↮_)

private
  variable
    K K′  : Cone
    A B   : J.Obj
    X Y Z : Obj
    q     : K ⇨ K′

record Limit : Set (o ⊔ ℓ ⊔ e ⊔ o′ ⊔ ℓ′ ⊔ e′) where
  field
    terminal : Terminal Cones

  module terminal = Terminal terminal

  open terminal using () renaming (⊤ to limit) public
  open Cone limit hiding (apex) renaming (N to apex; ψ to proj; commute to limit-commute) public

  rep-cone : ∀ K → K ⇨ limit
  rep-cone K = terminal.! {K}

  rep : ∀ K → Cone.N K ⇒ apex
  rep K = arr
    where open _⇨_ (rep-cone K)

  unrep : X ⇒ apex → Cone
  unrep f = record {
    apex        = record
      { ψ       = λ A → proj A ∘ f
      ; commute = λ g → pullˡ (limit-commute g)
      }
    }

  conify : (f : X ⇒ apex) → unrep f ⇨ limit
  conify f = record
    { arr     = f
    ; commute = refl
    }

  commute : proj A ∘ rep K ≈ Cone.ψ K A
  commute {K = K} = _⇨_.commute (rep-cone K)

  unrep-cone : (K ⇨ limit) → Cone
  unrep-cone f = unrep (_⇨_.arr f)

  g-η : ∀ {f : X ⇒ apex} → rep (unrep f) ≈ f
  g-η {f = f} = terminal.!-unique (conify f)

  η-cone : Cones [ rep-cone limit ≈ Category.id Cones ]
  η-cone = terminal.⊤-id (rep-cone limit)

  η : rep limit ≈ id
  η = η-cone

  rep-cone∘ : Cones [ Cones [ rep-cone K ∘ q ] ≈ rep-cone K′ ]
  rep-cone∘ {K = K} {q = q} = Equiv.sym (terminal.!-unique (Cones [ rep-cone K ∘ q ]))

  rep∘ : ∀ {q : K′ ⇨ K} → rep K ∘ _⇨_.arr q ≈ rep K′
  rep∘ {q = q} = rep-cone∘ {q = q}

  rep-cone-self-id : Cones [ rep-cone limit ≈ Cones.id ]
  rep-cone-self-id = terminal.!-unique Cones.id

  rep-self-id : rep limit ≈ id
  rep-self-id = rep-cone-self-id

open Limit

up-to-iso-cone : (L₁ L₂ : Limit) → limit L₁ ⇔ limit L₂
up-to-iso-cone L₁ L₂ = T.up-to-iso Cones (terminal L₁) (terminal L₂)

up-to-iso : (L₁ L₂ : Limit) → apex L₁ ≅ apex L₂
up-to-iso L₁ L₂ = iso-cone⇒iso-apex (up-to-iso-cone L₁ L₂)

transport-by-iso-cone : (L : Limit) → limit L ⇔ K → Limit
transport-by-iso-cone L L⇿K = record
  { terminal = T.transport-by-iso Cones (terminal L) L⇿K
  }

transport-by-iso : (L : Limit) → apex L ≅ X → Limit
transport-by-iso L L≅X = transport-by-iso-cone L (proj₂ p)
  where p = cone-resp-iso (limit L) L≅X