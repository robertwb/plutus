module ContractHome.State
  ( defaultState
  , handleAction
  ) where

import Prelude
import Contract.Lenses (_executionState)
import Contract.State (mkInitialState) as Contract
import Contract.Types (State) as Contract
import ContractHome.Lenses (_selectedContractIndex, _status)
import ContractHome.Types (ContractStatus(..), State, Action(..))
import Data.Array (catMaybes)
import Data.BigInteger (fromInt)
import Data.Foldable (foldl)
import Data.Lens (assign, over)
import Data.List as List
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Tuple.Nested ((/\))
import Halogen (HalogenM)
import Marlowe.Execution (nextState)
import Marlowe.Extended (TemplateContent(..), fillTemplate, toCore)
import Marlowe.Market.Contract1 as Contract1
import Marlowe.Market.Contract3 as Contract3
import Marlowe.Semantics (Input(..), Party(..), Slot(..), SlotInterval(..), Token(..), TransactionInput(..))

-- FIXME: debug purposes only, delete later
filledContract1 :: Maybe Contract.State
filledContract1 =
  let
    templateContent =
      TemplateContent
        { slotContent:
            Map.fromFoldable
              [ "aliceTimeout" /\ fromInt 10
              , "arbitrageTimeout" /\ fromInt 12
              , "bobTimeout" /\ fromInt 15
              , "depositSlot" /\ fromInt 17
              ]
        , valueContent:
            Map.fromFoldable
              [ "amount" /\ fromInt 1500
              ]
        }

    participants =
      Map.fromFoldable
        [ (Role "alice") /\ Just "Alice user"
        , (Role "bob") /\ Just "Bob user"
        , (Role "carol") /\ Nothing
        ]

    mContract = toCore $ fillTemplate templateContent Contract1.extendedContract
  in
    mContract <#> \contract -> Contract.mkInitialState "dummy contract 1" zero contract Contract1.metaData participants (Just $ Role "alice")

filledContract2 :: Maybe Contract.State
filledContract2 = do
  let
    templateContent =
      TemplateContent
        { slotContent:
            Map.fromFoldable
              [ "aliceTimeout" /\ fromInt 10
              , "arbitrageTimeout" /\ fromInt 12
              , "bobTimeout" /\ fromInt 15
              , "depositSlot" /\ fromInt 17
              ]
        , valueContent:
            Map.fromFoldable
              [ "amount" /\ fromInt 1500
              ]
        }

    participants =
      Map.fromFoldable
        [ (Role "alice") /\ Just "Alice user"
        , (Role "bob") /\ Just "Bob user"
        , (Role "carol") /\ Nothing
        ]

    transactions =
      [ TransactionInput
          { interval:
              (SlotInterval (Slot $ fromInt 0) (Slot $ fromInt 0))
          , inputs:
              List.singleton
                $ IDeposit (Role "alice") (Role "alice") (Token "" "") (fromInt 1500)
          }
      ]

    nextState' :: Contract.State -> TransactionInput -> Contract.State
    nextState' state txInput = over _executionState (flip nextState $ txInput) state
  contract <- toCore $ fillTemplate templateContent Contract3.extendedContract
  initialState <- pure $ Contract.mkInitialState "dummy contract 2" zero contract Contract3.metaData participants (Just $ Role "alice")
  pure $ foldl nextState' initialState transactions

defaultState :: State
defaultState =
  { status: Running
  , contracts: catMaybes [ filledContract1, filledContract2 ]
  -- , contracts: mempty
  , selectedContractIndex: Nothing
  }

handleAction ::
  forall m slots msg.
  Action -> HalogenM State Action slots msg m Unit
handleAction ToggleTemplateLibraryCard = pure unit -- handled in Play

handleAction (SelectView view) = assign _status view

handleAction (OpenContract ix) = assign _selectedContractIndex $ Just ix
