{-# OPTIONS --without-K --safe #-}

module Regression where

open import Level
open import Relation.Binary using (Rel; IsEquivalence)

-- open import Categories.Category.Core
record Category (o ℓ e : Level) : Set (suc (o ⊔ ℓ ⊔ e)) where
  eta-equality
  infix  4 _≈_ _⇒_
  infixr 9 _∘_

  field
    Obj : Set o
    _⇒_ : Rel Obj ℓ
    _≈_ : ∀ {A B} → Rel (A ⇒ B) e

    id  : ∀ {A} → (A ⇒ A)
    _∘_ : ∀ {A B C} → (B ⇒ C) → (A ⇒ B) → (A ⇒ C)

  field
    assoc     : ∀ {A B C D} {f : A ⇒ B} {g : B ⇒ C} {h : C ⇒ D} → (h ∘ g) ∘ f ≈ h ∘ (g ∘ f)
    -- We add a symmetric proof of associativity so that the opposite category of the
    -- opposite category is definitionally equal to the original category. See how
    -- `op` is implemented.
    sym-assoc : ∀ {A B C D} {f : A ⇒ B} {g : B ⇒ C} {h : C ⇒ D} → h ∘ (g ∘ f) ≈ (h ∘ g) ∘ f
    identityˡ : ∀ {A B} {f : A ⇒ B} → id ∘ f ≈ f
    identityʳ : ∀ {A B} {f : A ⇒ B} → f ∘ id ≈ f
    -- We add a proof of "neutral" identity proof, in order to ensure the opposite of
    -- constant functor is definitionally equal to itself.
    identity² : ∀ {A} → id ∘ id {A} ≈ id {A}
    equiv     : ∀ {A B} → IsEquivalence (_≈_ {A} {B})
    ∘-resp-≈  : ∀ {A B C} {f h : B ⇒ C} {g i : A ⇒ B} → f ≈ h → g ≈ i → f ∘ g ≈ h ∘ i

  module Equiv {A B : Obj} = IsEquivalence (equiv {A} {B})

  CommutativeSquare : ∀ {A B C D} → (f : A ⇒ B) (g : A ⇒ C) (h : B ⇒ D) (i : C ⇒ D) → Set _
  CommutativeSquare f g h i = h ∘ f ≈ i ∘ g

infix 10  _[_,_] _[_≈_] _[_∘_]

_[_,_] : ∀ {o ℓ e} → (C : Category o ℓ e) → (X : Category.Obj C) → (Y : Category.Obj C) → Set ℓ
_[_,_] = Category._⇒_

_[_≈_] : ∀ {o ℓ e} → (C : Category o ℓ e) → ∀ {X Y} (f g : C [ X , Y ]) → Set e
_[_≈_] = Category._≈_

_[_∘_] : ∀ {o ℓ e} → (C : Category o ℓ e) → ∀ {X Y Z} (f : C [ Y , Z ]) → (g : C [ X , Y ]) → C [ X , Z ]
_[_∘_] = Category._∘_

module Inner {x₁ x₂ x₃} (CC : Category x₁ x₂ x₃) where

  open import Level
  private
    variable
      o ℓ e o′ ℓ′ e′ o″ ℓ″ e″ : Level

  open import Data.Product using (_×_; Σ; _,_; curry′; proj₁; proj₂; zip; map; <_,_>; swap)

  zipWith : ∀ {a b c p q r s} {A : Set a} {B : Set b} {C : Set c} {P : A → Set p} {Q : B → Set q} {R : C → Set r} {S : (x : C) → R x → Set s} (_∙_ : A → B → C) → (_∘_ : ∀ {x y} → P x → Q y → R (x ∙ y)) → (_*_ : (x : C) → (y : R x) → S x y) → (x : Σ A P) → (y : Σ B Q) → S (proj₁ x ∙ proj₁ y) (proj₂ x ∘ proj₂ y)
  zipWith _∙_ _∘_ _*_ (a , p) (b , q) = (a ∙ b) * (p ∘ q)
  syntax zipWith f g h = f -< h >- g

  record Functor (C : Category o ℓ e) (D : Category o′ ℓ′ e′) : Set (o ⊔ ℓ ⊔ e ⊔ o′ ⊔ ℓ′ ⊔ e′) where
    eta-equality
    private module C = Category C
    private module D = Category D

    field
      F₀ : C.Obj → D.Obj
      F₁ : ∀ {A B} (f : C [ A , B ]) → D [ F₀ A , F₀ B ]
      identity     : ∀ {A} → D [ F₁ (C.id {A}) ≈ D.id ]
      homomorphism : ∀ {X Y Z} {f : C [ X , Y ]} {g : C [ Y , Z ]} →
                       D [ F₁ (C [ g ∘ f ]) ≈ D [ F₁ g ∘ F₁ f ] ]
      F-resp-≈     : ∀ {A B} {f g : C [ A , B ]} → C [ f ≈ g ] → D [ F₁ f ≈ F₁ g ]

  Product : (C : Category o ℓ e) (D : Category o′ ℓ′ e′) → Category (o ⊔ o′) (ℓ ⊔ ℓ′) (e ⊔ e′)
  Product C D = record
    { Obj       = C.Obj × D.Obj
    ; _⇒_       = C._⇒_ -< _×_ >- D._⇒_
    ; _≈_       = C._≈_ -< _×_ >- D._≈_
    ; _∘_       = zip C._∘_ D._∘_
    ; id        = C.id , D.id
    ; assoc     = C.assoc , D.assoc
    ; sym-assoc = C.sym-assoc , D.sym-assoc
    ; identityˡ = C.identityˡ , D.identityˡ
    ; identityʳ = C.identityʳ , D.identityʳ
    ; identity² = C.identity² , D.identity²
    ; equiv     = record
      { refl  = C.Equiv.refl , D.Equiv.refl
      ; sym   = map C.Equiv.sym D.Equiv.sym
      ; trans = zip C.Equiv.trans D.Equiv.trans
      }
    ; ∘-resp-≈  = zip C.∘-resp-≈ D.∘-resp-≈
    }
    where module C = Category C
          module D = Category D

  Bifunctor : Category o ℓ e → Category o′ ℓ′ e′ → Category o″ ℓ″ e″ → Set _
  Bifunctor C D E = Functor (Product C D) E

  private
    module CC = Category CC

  open CC hiding (id; identityˡ; identityʳ; assoc)

  infix 4 _≅_
  record _≅_ (A B : Obj) : Set (x₂) where
    field
      from : A ⇒ B
      to   : B ⇒ A

  private
    variable
      X Y Z W : Obj
      f g h : X ⇒ Y

  record Monoidal : Set (x₁ ⊔ x₂ ⊔ x₃) where
    infixr 10 _⊗₀_ _⊗₁_

    field
      ⊗  : Bifunctor CC CC CC

    module ⊗ = Functor ⊗

    open Functor ⊗

    _⊗₀_ : Obj → Obj → Obj
    _⊗₀_ = curry′ F₀

    -- this is also 'curry', but a very-dependent version
    _⊗₁_ : X ⇒ Y → Z ⇒ W → X ⊗₀ Z ⇒ Y ⊗₀ W
    f ⊗₁ g = F₁ (f , g)

    field
      associator : (X ⊗₀ Y) ⊗₀ Z ≅ X ⊗₀ (Y ⊗₀ Z)

    module associator {X} {Y} {Z} = _≅_ (associator {X} {Y} {Z})

    -- for exporting, it makes sense to use the above long names, but for
    -- internal consumption, the traditional (short!) categorical names are more
    -- convenient. However, they are not symmetric, even though the concepts are, so
    -- we'll use ⇒ and ⇐ arrows to indicate that
    private
      α⇒ = associator.from
      α⇐ = λ {X} {Y} {Z} → associator.to {X} {Y} {Z}

    field
      assoc-commute-from   : CommutativeSquare ((f ⊗₁ g) ⊗₁ h) α⇒ α⇒ (f ⊗₁ (g ⊗₁ h))
      assoc-commute-to     : CommutativeSquare (f ⊗₁ (g ⊗₁ h)) α⇐ α⇐ ((f ⊗₁ g) ⊗₁ h)
