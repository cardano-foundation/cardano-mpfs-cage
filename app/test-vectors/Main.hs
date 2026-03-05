-- | Generate language-neutral JSON test vectors for the
-- MPFS cage validator specification.
--
-- Outputs vectors covering:
--
-- - Insert\/delete\/update operations with proofs
-- - PlutusData encoding of cage types
-- - Asset name derivation from TxOutRef
module Main (main) where

import Cardano.MPFS.Cage.AssetName (deriveAssetName)
import Cardano.MPFS.Cage.Proof
    ( serializeProof
    , toProofSteps
    )
import Cardano.MPFS.Cage.Types
import Control.Lens (simple)
import Data.Aeson ((.=))
import Data.Aeson qualified as Aeson
import Data.Aeson.Encode.Pretty (encodePretty)
import Data.ByteString (ByteString)
import Data.ByteString qualified as BS
import Data.ByteString.Base16 qualified as B16
import Data.ByteString.Lazy.Char8 qualified as BL8
import Data.Text (Text)
import Data.Text.Encoding qualified as T
import MPF.Backend.Pure
    ( MPFInMemoryDB
    , MPFPure
    , emptyMPFInMemoryDB
    , runMPFPure
    , runMPFPureTransaction
    )
import MPF.Backend.Standalone
    ( MPFStandalone (..)
    , MPFStandaloneCodecs (..)
    )
import MPF.Hashes
    ( MPFHash
    , fromHexKVHashes
    , isoMPFHash
    , mpfHashing
    , root
    )
import MPF.Insertion (inserting)
import MPF.Proof.Insertion
    ( MPFProof
    , mkMPFInclusionProof
    )
import PlutusCore.Data (Data (..))
import PlutusTx.Builtins.Internal
    ( BuiltinByteString (..)
    , BuiltinData (..)
    )
import PlutusTx.IsData.Class (ToData (..))

-- | ByteString codecs for MPF standalone backend.
bsCodecs
    :: MPFStandaloneCodecs ByteString ByteString MPFHash
bsCodecs =
    MPFStandaloneCodecs
        { mpfKeyCodec = simple
        , mpfValueCodec = simple
        , mpfNodeCodec = isoMPFHash
        }

-- | Insert a key-value pair.
insertKV :: ByteString -> ByteString -> MPFPure ()
insertKV k v =
    runMPFPureTransaction bsCodecs
        $ inserting
            []
            fromHexKVHashes
            mpfHashing
            MPFStandaloneKVCol
            MPFStandaloneMPFCol
            k
            v

-- | Get the root hash.
getRootHash :: MPFPure (Maybe ByteString)
getRootHash =
    runMPFPureTransaction bsCodecs
        $ root MPFStandaloneMPFCol []

-- | Get inclusion proof for a key.
getProof
    :: ByteString
    -> MPFPure (Maybe (MPFProof MPFHash))
getProof k =
    runMPFPureTransaction bsCodecs
        $ mkMPFInclusionProof
            []
            fromHexKVHashes
            mpfHashing
            MPFStandaloneMPFCol
            k

-- | Build a tree from key-value pairs.
buildTree
    :: [(ByteString, ByteString)] -> MPFInMemoryDB
buildTree kvs =
    snd
        $ runMPFPure emptyMPFInMemoryDB
        $ mapM_ (uncurry insertKV) kvs

-- | Get proof and root from a database (must exist).
getVec
    :: MPFInMemoryDB
    -> ByteString
    -> (MPFProof MPFHash, ByteString)
getVec db k =
    case fst
        $ runMPFPure db
        $ (,) <$> getProof k <*> getRootHash of
        (Just p, Just r) -> (p, r)
        _ -> error "getVec: missing proof or root"

-- | Get just the root (must exist).
getRoot :: MPFInMemoryDB -> ByteString -> ByteString
getRoot db k = snd (getVec db k)

-- | Hex-encode a ByteString for JSON output.
toHex :: ByteString -> Text
toHex = T.decodeUtf8 . B16.encode

-- | Encode a PlutusData value to its Data AST
-- and render as JSON.
dataToJson :: Data -> Aeson.Value
dataToJson (Constr tag fields) =
    Aeson.object
        [ "constructor" .= tag
        , "fields" .= map dataToJson fields
        ]
dataToJson (I n) = Aeson.toJSON n
dataToJson (B bs) =
    Aeson.object ["bytes" .= toHex bs]
dataToJson (List xs) =
    Aeson.toJSON (map dataToJson xs)
dataToJson (Map kvs) =
    Aeson.toJSON
        $ map
            ( \(k, v) ->
                Aeson.object
                    [ "k" .= dataToJson k
                    , "v" .= dataToJson v
                    ]
            )
            kvs

-- | Encode a ToData value as JSON PlutusData.
toDataJson :: (ToData a) => a -> Aeson.Value
toDataJson x =
    let BuiltinData d = toBuiltinData x
    in  dataToJson d

-- | Create a proof vector JSON object.
mkProofVector
    :: Text
    -> ByteString
    -> ByteString
    -> ByteString
    -> ByteString
    -> MPFProof MPFHash
    -> Aeson.Value
mkProofVector desc key value initialRoot expectedRoot proof =
    Aeson.object
        [ "description" .= desc
        , "initialRoot" .= toHex initialRoot
        , "key" .= toHex key
        , "value" .= toHex value
        , "expectedRoot" .= toHex expectedRoot
        , "proof"
            .= Aeson.object
                [ "steps"
                    .= map toDataJson (toProofSteps proof)
                , "cbor"
                    .= toHex (serializeProof proof)
                ]
        ]

main :: IO ()
main = do
    let vectors = Aeson.object ["vectors" .= allVectors]
    BL8.putStrLn (encodePretty vectors)

-- | The empty root (32 zero bytes).
emptyRoot :: ByteString
emptyRoot = BS.replicate 32 0

allVectors :: [Aeson.Value]
allVectors =
    proofVectors
        ++ assetNameVectors
        ++ datumEncodingVectors

-- -----------------------------------------------------------
-- Proof vectors
-- -----------------------------------------------------------

proofVectors :: [Aeson.Value]
proofVectors =
    [ -- 1. Insert into empty trie
      let db = buildTree [("\xab", "\xcd")]
          (p, r) = getVec db "\xab"
      in  mkProofVector
            "insert into empty trie"
            "\xab"
            "\xcd"
            emptyRoot
            r
            p
    , -- 2. Insert creating fork
      let db1 = buildTree [("\x00", "\xaa")]
          r1 = getRoot db1 "\x00"
          db2 =
            buildTree
                [("\x00", "\xaa"), ("\x80", "\xbb")]
          (p2, r2) = getVec db2 "\x80"
      in  mkProofVector
            "insert creating fork (bit 0 diverge)"
            "\x80"
            "\xbb"
            r1
            r2
            p2
    , -- 3. Insert with shared prefix
      let db1 = buildTree [("\xab\x00", "\x11")]
          r1 = getRoot db1 "\xab\x00"
          db2 =
            buildTree
                [ ("\xab\x00", "\x11")
                , ("\xab\x80", "\x22")
                ]
          (p2, r2) = getVec db2 "\xab\x80"
      in  mkProofVector
            "insert with shared prefix"
            "\xab\x80"
            "\x22"
            r1
            r2
            p2
    , -- 4. Inclusion proof for existing key
      let db =
            buildTree
                [ ("\x00", "\x01")
                , ("\x40", "\x02")
                , ("\x80", "\x03")
                ]
          (p, r) = getVec db "\x40"
      in  mkProofVector
            "inclusion proof for middle key"
            "\x40"
            "\x02"
            r
            r
            p
    ]

-- -----------------------------------------------------------
-- Asset name derivation vectors
-- -----------------------------------------------------------

assetNameVectors :: [Aeson.Value]
assetNameVectors =
    [ let txId = BS.pack [0x01 .. 0x20]
          ref = OnChainTxOutRef (BuiltinByteString txId) 0
          name = deriveAssetName ref
      in  Aeson.object
            [ "description"
                .= ("asset name from TxOutRef index 0" :: Text)
            , "txId" .= toHex txId
            , "outputIndex" .= (0 :: Int)
            , "expectedAssetName" .= toHex name
            ]
    , let txId = BS.pack [0x01 .. 0x20]
          ref = OnChainTxOutRef (BuiltinByteString txId) 1
          name = deriveAssetName ref
      in  Aeson.object
            [ "description"
                .= ("asset name from TxOutRef index 1" :: Text)
            , "txId" .= toHex txId
            , "outputIndex" .= (1 :: Int)
            , "expectedAssetName" .= toHex name
            ]
    , let txId = BS.replicate 32 0
          ref = OnChainTxOutRef (BuiltinByteString txId) 255
          name = deriveAssetName ref
      in  Aeson.object
            [ "description"
                .= ("asset name from zero txId index 255" :: Text)
            , "txId" .= toHex txId
            , "outputIndex" .= (255 :: Int)
            , "expectedAssetName" .= toHex name
            ]
    ]

-- -----------------------------------------------------------
-- Datum encoding vectors
-- -----------------------------------------------------------

datumEncodingVectors :: [Aeson.Value]
datumEncodingVectors =
    [ let state =
            OnChainTokenState
                { stateOwner =
                    BuiltinByteString (BS.replicate 28 0xaa)
                , stateRoot =
                    OnChainRoot (BS.replicate 32 0xbb)
                , stateMaxFee = 2000000
                , stateProcessTime = 300000
                , stateRetractTime = 600000
                }
      in  Aeson.object
            [ "description" .= ("StateDatum encoding" :: Text)
            , "type" .= ("CageDatum" :: Text)
            , "plutusData" .= toDataJson (StateDatum state)
            ]
    , let req =
            OnChainRequest
                { requestToken =
                    OnChainTokenId
                        $ BuiltinByteString
                        $ BS.replicate 32 0xcc
                , requestOwner =
                    BuiltinByteString (BS.replicate 28 0xdd)
                , requestKey = BS.pack [0x01, 0x02, 0x03]
                , requestValue =
                    OpInsert (BS.pack [0x04, 0x05])
                , requestFee = 1000000
                , requestSubmittedAt = 1700000000000
                }
      in  Aeson.object
            [ "description"
                .= ("RequestDatum with OpInsert" :: Text)
            , "type" .= ("CageDatum" :: Text)
            , "plutusData" .= toDataJson (RequestDatum req)
            ]
    , let ref =
            OnChainTxOutRef
                (BuiltinByteString $ BS.replicate 32 0xee)
                0
      in  Aeson.object
            [ "description"
                .= ("MintRedeemer Minting" :: Text)
            , "type" .= ("MintRedeemer" :: Text)
            , "plutusData"
                .= toDataJson (Minting (Mint ref))
            ]
    , Aeson.object
        [ "description"
            .= ("MintRedeemer Burning" :: Text)
        , "type" .= ("MintRedeemer" :: Text)
        , "plutusData" .= toDataJson Burning
        ]
    , Aeson.object
        [ "description"
            .= ("UpdateRedeemer End" :: Text)
        , "type" .= ("UpdateRedeemer" :: Text)
        , "plutusData" .= toDataJson End
        ]
    , Aeson.object
        [ "description"
            .= ("UpdateRedeemer Reject" :: Text)
        , "type" .= ("UpdateRedeemer" :: Text)
        , "plutusData" .= toDataJson Reject
        ]
    , Aeson.object
        [ "description"
            .= ("OpUpdate encoding" :: Text)
        , "type" .= ("OnChainOperation" :: Text)
        , "plutusData"
            .= toDataJson
                (OpUpdate "\x01\x02" "\x03\x04")
        ]
    , Aeson.object
        [ "description"
            .= ("OpDelete encoding" :: Text)
        , "type" .= ("OnChainOperation" :: Text)
        , "plutusData"
            .= toDataJson (OpDelete "\xaa\xbb")
        ]
    ]
