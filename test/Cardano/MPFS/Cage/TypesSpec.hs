module Cardano.MPFS.Cage.TypesSpec (spec) where

import Cardano.MPFS.Cage.AssetName (deriveAssetName)
import Cardano.MPFS.Cage.Types
import Data.ByteString qualified as BS
import PlutusCore.Data (Data (..))
import PlutusTx.Builtins.Internal
    ( BuiltinByteString (..)
    , BuiltinData (..)
    )
import PlutusTx.IsData.Class
    ( FromData (..)
    , ToData (..)
    )
import Test.Hspec

-- | Helper: roundtrip via ToData/FromData.
roundtrip
    :: (ToData a, FromData a, Show a, Eq a)
    => a
    -> Expectation
roundtrip x =
    fromBuiltinData (toBuiltinData x)
        `shouldBe` Just x

-- | Helper: verify constructor index.
constrIndex :: (ToData a) => a -> Integer
constrIndex x =
    let BuiltinData d = toBuiltinData x
    in  case d of
            Constr n _ -> n
            _ ->
                error
                    "expected Constr"

spec :: Spec
spec = do
    describe "OnChainTokenId" $ do
        it "roundtrips via ToData/FromData" $ do
            let tid =
                    OnChainTokenId
                        $ BuiltinByteString
                        $ BS.replicate 32 0xab
            roundtrip tid

        it "uses constructor index 0" $ do
            let tid =
                    OnChainTokenId
                        $ BuiltinByteString
                            "test"
            constrIndex tid `shouldBe` 0

    describe "OnChainTxOutRef" $ do
        it "roundtrips via ToData/FromData" $ do
            let ref =
                    OnChainTxOutRef
                        (BuiltinByteString $ BS.replicate 32 0x01)
                        42
            roundtrip ref

        it "uses constructor index 0" $ do
            let ref =
                    OnChainTxOutRef
                        (BuiltinByteString "tx")
                        0
            constrIndex ref `shouldBe` 0

    describe "OnChainOperation" $ do
        it "roundtrips OpInsert" $ do
            roundtrip (OpInsert "value")

        it "roundtrips OpDelete" $ do
            roundtrip (OpDelete "old")

        it "roundtrips OpUpdate" $ do
            roundtrip (OpUpdate "old" "new")

        it "OpInsert uses constructor 0"
            $ constrIndex (OpInsert "v")
            `shouldBe` 0

        it "OpDelete uses constructor 1"
            $ constrIndex (OpDelete "v")
            `shouldBe` 1

        it "OpUpdate uses constructor 2"
            $ constrIndex (OpUpdate "o" "n")
            `shouldBe` 2

    describe "OnChainRoot" $ do
        it "roundtrips via ToData/FromData" $ do
            let r =
                    OnChainRoot (BS.replicate 32 0xff)
            roundtrip r

    describe "OnChainRequest" $ do
        it "roundtrips via ToData/FromData" $ do
            let req =
                    OnChainRequest
                        { requestToken =
                            OnChainTokenId
                                (BuiltinByteString $ BS.replicate 32 0xcc)
                        , requestOwner =
                            BuiltinByteString
                                $ BS.replicate 28 0xdd
                        , requestKey = "key"
                        , requestValue =
                            OpInsert "val"
                        , requestFee = 2000000
                        , requestSubmittedAt =
                            1700000000000
                        }
            roundtrip req

    describe "OnChainTokenState" $ do
        it "roundtrips via ToData/FromData" $ do
            let state =
                    OnChainTokenState
                        { stateOwner =
                            BuiltinByteString
                                $ BS.replicate 28 0xaa
                        , stateRoot =
                            OnChainRoot
                                $ BS.replicate 32 0xbb
                        , stateMaxFee = 2000000
                        , stateProcessTime = 300000
                        , stateRetractTime = 600000
                        }
            roundtrip state

    describe "CageDatum" $ do
        it "roundtrips RequestDatum" $ do
            let req =
                    OnChainRequest
                        { requestToken =
                            OnChainTokenId
                                (BuiltinByteString "tok")
                        , requestOwner =
                            BuiltinByteString "own"
                        , requestKey = "k"
                        , requestValue =
                            OpInsert "v"
                        , requestFee = 1000000
                        , requestSubmittedAt = 0
                        }
            roundtrip (RequestDatum req)

        it "roundtrips StateDatum" $ do
            let state =
                    OnChainTokenState
                        { stateOwner =
                            BuiltinByteString "own"
                        , stateRoot =
                            OnChainRoot "root"
                        , stateMaxFee = 0
                        , stateProcessTime = 1
                        , stateRetractTime = 1
                        }
            roundtrip (StateDatum state)

        it "RequestDatum uses constructor 0"
            $ let req =
                    OnChainRequest
                        { requestToken =
                            OnChainTokenId
                                (BuiltinByteString "t")
                        , requestOwner =
                            BuiltinByteString "o"
                        , requestKey = "k"
                        , requestValue =
                            OpInsert "v"
                        , requestFee = 0
                        , requestSubmittedAt = 0
                        }
              in  constrIndex (RequestDatum req)
                    `shouldBe` 0

        it "StateDatum uses constructor 1"
            $ let state =
                    OnChainTokenState
                        { stateOwner =
                            BuiltinByteString "o"
                        , stateRoot =
                            OnChainRoot "r"
                        , stateMaxFee = 0
                        , stateProcessTime = 1
                        , stateRetractTime = 1
                        }
              in  constrIndex (StateDatum state)
                    `shouldBe` 1

    describe "MintRedeemer" $ do
        it "roundtrips Minting" $ do
            let m =
                    Minting
                        $ Mint
                        $ OnChainTxOutRef
                            (BuiltinByteString "tx")
                            0
            roundtrip m

        it "roundtrips Migrating" $ do
            let m =
                    Migrating
                        $ Migration
                            (BuiltinByteString "pol")
                            (OnChainTokenId $ BuiltinByteString "tid")
            roundtrip m

        it "roundtrips Burning"
            $ roundtrip Burning

        it "Minting uses constructor 0"
            $ let m =
                    Minting
                        $ Mint
                        $ OnChainTxOutRef
                            (BuiltinByteString "tx")
                            0
              in  constrIndex m `shouldBe` 0

        it "Migrating uses constructor 1"
            $ let m =
                    Migrating
                        $ Migration
                            (BuiltinByteString "p")
                            (OnChainTokenId $ BuiltinByteString "t")
              in  constrIndex m `shouldBe` 1

        it "Burning uses constructor 2"
            $ constrIndex Burning
            `shouldBe` 2

    describe "UpdateRedeemer" $ do
        it "roundtrips End" $ roundtrip End

        it "roundtrips Contribute" $ do
            let r =
                    Contribute
                        $ OnChainTxOutRef
                            (BuiltinByteString "tx")
                            5
            roundtrip r

        it "roundtrips Retract" $ do
            let r =
                    Retract
                        $ OnChainTxOutRef
                            (BuiltinByteString "tx")
                            3
            roundtrip r

        it "roundtrips Reject" $ roundtrip Reject

        it "roundtrips Modify with empty proofs"
            $ roundtrip (Modify [])

        it "End uses constructor 0"
            $ constrIndex End
            `shouldBe` 0

        it "Contribute uses constructor 1"
            $ let r =
                    Contribute
                        $ OnChainTxOutRef
                            (BuiltinByteString "tx")
                            0
              in  constrIndex r `shouldBe` 1

        it "Modify uses constructor 2"
            $ constrIndex (Modify [])
            `shouldBe` 2

        it "Retract uses constructor 3"
            $ let r =
                    Retract
                        $ OnChainTxOutRef
                            (BuiltinByteString "tx")
                            0
              in  constrIndex r `shouldBe` 3

        it "Reject uses constructor 4"
            $ constrIndex Reject
            `shouldBe` 4

    describe "ProofStep" $ do
        it "roundtrips Branch" $ do
            let step =
                    Branch
                        0
                        (BS.replicate 128 0x00)
            roundtrip step

        it "roundtrips Fork" $ do
            let step =
                    Fork
                        1
                        Neighbor
                            { neighborNibble = 5
                            , neighborPrefix = "pfx"
                            , neighborRoot =
                                BS.replicate 32 0xaa
                            }
            roundtrip step

        it "roundtrips Leaf" $ do
            let step = Leaf 2 "key" "val"
            roundtrip step

        it "Branch uses constructor 0"
            $ constrIndex (Branch 0 "nb")
            `shouldBe` 0

        it "Fork uses constructor 1"
            $ constrIndex
                (Fork 0 $ Neighbor 0 "" "")
            `shouldBe` 1

        it "Leaf uses constructor 2"
            $ constrIndex (Leaf 0 "" "")
            `shouldBe` 2

    describe "Neighbor" $ do
        it "roundtrips via ToData/FromData" $ do
            let n =
                    Neighbor
                        { neighborNibble = 7
                        , neighborPrefix = "prefix"
                        , neighborRoot =
                            BS.replicate 32 0xbb
                        }
            roundtrip n

    describe "deriveAssetName" $ do
        it "produces 32-byte output" $ do
            let ref =
                    OnChainTxOutRef
                        (BuiltinByteString $ BS.replicate 32 0x01)
                        0
            BS.length (deriveAssetName ref)
                `shouldBe` 32

        it "different index gives different name"
            $ do
                let txId =
                        BuiltinByteString
                            $ BS.replicate 32 0x01
                    ref0 = OnChainTxOutRef txId 0
                    ref1 = OnChainTxOutRef txId 1
                deriveAssetName ref0
                    `shouldNotBe` deriveAssetName ref1

        it "different txId gives different name"
            $ do
                let ref0 =
                        OnChainTxOutRef
                            (BuiltinByteString $ BS.replicate 32 0x01)
                            0
                    ref1 =
                        OnChainTxOutRef
                            (BuiltinByteString $ BS.replicate 32 0x02)
                            0
                deriveAssetName ref0
                    `shouldNotBe` deriveAssetName ref1
