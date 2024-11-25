// Decompiled by SuiGPT
module Nft::nft {

    // ----- Use Statements -----

    use sui::balance;
    use sui::sui;
    use sui::event;
    use sui::package;
    use sui::display;
    use std::string;
    use sui::coin;
    use sui::clock;
    use sui::bcs;
    use Archive::cap_vault;
    use Archive::version;
    use Archive::archieve;
    // ----- Structs -----

    public struct BirdNFT has store, key {
        id: object::UID,
        xid: u128,
        types: u16,
        sub_type: u16,
        rare: u16,
        value: u64,
    }

    public struct NFT has drop {
        dummy_field: bool,
    }

    public struct NFTBurn has copy, drop {
        nft_id: object::ID,
        owner: address,
        xid: u128,
        types: u16,
        sub_type: u16,
        rare: u16,
        value: u64,
    }

    public struct NFTDeposited has copy, drop {
        owner: address,
        batchId: u128,
        ids: vector<object::ID>,
        xids: vector<u128>,
        types: vector<u16>,
        sub_types: vector<u16>,
        rares: vector<u16>,
        values: vector<u64>,
        nonce: u128,
    }

    public struct NFTWithdrawn has copy, drop {
        id: object::ID,
        owner: address,
        xid: u128,
        types: u16,
        sub_type: u16,
        rare: u16,
        value: u64,
        nonce: u128,
    }

    public struct NftAdminCap has store, key {
        id: object::UID,
    }

    public struct NftPegVault has store, key {
        id: object::UID,
        validator: option::Option<vector<u8>>,
        fee: balance::Balance<sui::SUI>,
    }

    // ----- Functions -----

    fun burnInt(
        bird_nft: BirdNFT,
        ctx: &tx_context::TxContext
    ): (object::ID, u128, u16, u16, u16, u64) {
        let nft_id = object::id(&bird_nft);
        let BirdNFT {
            id,
            xid,
            types,
            sub_type,
            rare,
            value,
        } = bird_nft;

        object::delete(id);

        event::emit<NFTBurn>(NFTBurn {
            nft_id,
            owner: tx_context::sender(ctx),
            xid,
            types,
            sub_type,
            rare,
            value,
        });

        (nft_id, xid, types, sub_type, rare, value)
    }

    fun init(
        nft: NFT,
        ctx: &mut tx_context::TxContext
    ) {
        let publisher = package::claim<NFT>(nft, ctx);
        let sender = tx_context::sender(ctx);

        transfer::public_transfer<display::Display<BirdNFT>>(setupNft(&publisher, ctx), sender);
        transfer::public_transfer<package::Publisher>(publisher, sender);

        let admin_cap = NftAdminCap {
            id: object::new(ctx)
        };
        transfer::public_transfer<NftAdminCap>(admin_cap, sender);

        let peg_vault = NftPegVault {
            id: object::new(ctx),
            validator: option::none<vector<u8>>(),
            fee: balance::zero<sui::SUI>(),
        };
        transfer::public_share_object<NftPegVault>(peg_vault);

        cap_vault::createVault<NftAdminCap>(ctx);
    }

    fun mintInt(
        xid: u128,
        bird_type: u16,
        sub_type: u16,
        rare: u16,
        value: u64,
        ctx: &mut tx_context::TxContext
    ): BirdNFT {
        BirdNFT {
            id: object::new(ctx),
            xid,
            types: bird_type,
            sub_type,
            rare,
            value,
        }
    }

    fun setupNft(
        publisher: &package::Publisher,
        ctx: &mut tx_context::TxContext
    ): display::Display<BirdNFT> {
        let mut data_fields_1 = vector::empty<string::String>();
        let data_fields_1_mut = &mut data_fields_1;
        vector::push_back(data_fields_1_mut, string::utf8(b"name"));
        vector::push_back(data_fields_1_mut, string::utf8(b"link"));
        vector::push_back(data_fields_1_mut, string::utf8(b"image_url"));
        vector::push_back(data_fields_1_mut, string::utf8(b"thumbnail_url"));
        vector::push_back(data_fields_1_mut, string::utf8(b"description"));
        vector::push_back(data_fields_1_mut, string::utf8(b"project_url"));
        vector::push_back(data_fields_1_mut, string::utf8(b"creator"));

        let mut data_fields_2 = vector::empty<string::String>();
        let data_fields_2_mut = &mut data_fields_2;
        vector::push_back(data_fields_2_mut, string::utf8(b"WORM - BIRDS GameFi Asset"));
        vector::push_back(data_fields_2_mut, string::utf8(b"https://asset.birds.dog/nft/{type}/{xid}.json"));
        vector::push_back(data_fields_2_mut, string::utf8(b"https://asset.birds.dog/img/{type}/{sub_type}.png"));
        vector::push_back(data_fields_2_mut, string::utf8(b"https://asset.birds.dog/img/{type}/{sub_type}-thumbnail.png"));
        vector::push_back(data_fields_2_mut, string::utf8(b"The leading memecoin & GameFi Telegram mini-app on the SuiNetwork"));
        vector::push_back(data_fields_2_mut, string::utf8(b"https://x.com/TheBirdsDogs"));
        vector::push_back(data_fields_2_mut, string::utf8(b"Bird Labs"));

        let mut display = display::new_with_fields<BirdNFT>(publisher, data_fields_1, data_fields_2, ctx);
        display::update_version(&mut display);
        display
    }

    public fun setValidator(
        admin_cap: &NftAdminCap,
        validator: vector<u8>,
        vault: &mut NftPegVault,
        version: &version::Version
    ) {
        version::checkVersion(version, 1);
        option::swap_or_fill(&mut vault.validator, validator);
    }

    public fun withdrawFee(
        admin_cap: &NftAdminCap,
        vault: &mut NftPegVault,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ): coin::Coin<sui::SUI> {
        version::checkVersion(version, 1);

        let fee_value = balance::value<sui::SUI>(&vault.fee);
        let split_fee = balance::split<sui::SUI>(&mut vault.fee, fee_value);
        coin::from_balance<sui::SUI>(split_fee, ctx)
    }

    public entry fun depositNft(
        signature: vector<u8>,
        payload: vector<u8>,
        vault: &mut NftPegVault,
        user_archieve: &mut archieve::UserArchieve,
        fee_coin: coin::Coin<sui::SUI>,
        version: &version::Version,
        clock: &clock::Clock,
        ctx: &mut tx_context::TxContext
    ) {
        version::checkVersion(version, 1);
        archieve::verifySignature(signature, payload, &vault.validator);

        let mut payload_bytes = bcs::new(payload);
        let owner = bcs::peel_address(&mut payload_bytes);
        let nonce = bcs::peel_u128(&mut payload_bytes);
        let values = bcs::peel_vec_u64(&mut payload_bytes);
        let rares = bcs::peel_vec_u16(&mut payload_bytes);
        let sub_types = bcs::peel_vec_u16(&mut payload_bytes);
        let types = bcs::peel_vec_u16(&mut payload_bytes);
        let xids = bcs::peel_vec_u128(&mut payload_bytes);

        assert!(
            vector::length(&xids) == vector::length(&types) &&
            vector::length(&xids) == vector::length(&sub_types) &&
            vector::length(&xids) == vector::length(&rares) &&
            vector::length(&xids) == vector::length(&values),
            5006
        );

        assert!(owner == tx_context::sender(ctx), 5003);
        assert!(bcs::peel_u64(&mut payload_bytes) > clock::timestamp_ms(clock), 5005);

        archieve::verUpdateNftPegNonce(nonce, user_archieve);

        assert!(
            coin::value(&fee_coin) >= bcs::peel_u64(&mut payload_bytes),
            5004
        );

        balance::join(&mut vault.fee, coin::into_balance(fee_coin));

        let mut ids = vector::empty<object::ID>();
        let mut index = 0;

        while (index < vector::length(&xids)) {
            let bird_nft = mintInt(
                *vector::borrow(&xids, index),
                *vector::borrow(&types, index),
                *vector::borrow(&sub_types, index),
                *vector::borrow(&rares, index),
                *vector::borrow(&values, index),
                ctx
            );

            vector::push_back(&mut ids, object::id(&bird_nft));
            index = index + 1;
            transfer::public_transfer(bird_nft, owner);
        };

        let nft_deposited_event = NFTDeposited {
            owner,
            batchId: bcs::peel_u128(&mut payload_bytes),
            ids,
            xids,
            types,
            sub_types,
            rares,
            values,
            nonce,
        };

        event::emit(nft_deposited_event);
    }

    public fun withdrawNft(
        user_archieve: &mut archieve::UserArchieve,
        bird_nft: BirdNFT,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        version::checkVersion(version, 1);
        let (id, xid, nft_type, sub_type, rare, value) = burnInt(bird_nft, ctx);
        let nonce = archieve::increaseGetNftDepegNonce(user_archieve);
        let nft_withdrawn = NFTWithdrawn {
            id,
            owner: tx_context::sender(ctx),
            xid,
            types: nft_type,
            sub_type,
            rare,
            value,
            nonce,
        };
        event::emit<NFTWithdrawn>(nft_withdrawn);
    }

    public fun burn(
        bird_nft: BirdNFT,
        ctx: &tx_context::TxContext
    ) {
        let (_, _, _, _, _, _) = burnInt(bird_nft, ctx);
    }
}