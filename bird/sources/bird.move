// Decompiled by SuiGPT
module Bird::bird;

use Archive::archieve;
use Archive::cap_vault;
use Archive::version;
use Nft::nft::{Self as nft, BirdNFT};
use sui::bcs;
use sui::event;

// ----- Use Statements -----

// ----- Structs -----

public struct AdminCap has store, key {
    id: object::UID,
}

public struct BIRD has drop {
    dummy_field: bool,
}

public struct BirdVault has store, key {
    id: object::UID,
    validator: option::Option<vector<u8>>,
}

public struct ClaimPreyRewardEvent has copy, drop {
    owner: address,
    hunt_id: u128,
    nonce: u128,
}

public struct FeedWormEvent has copy, drop {
    owner: address,
    bird_id: u64,
    power: u64,
    req_id: u128,
    nonce: u128,
    worm_id: address,
}

public struct PreyBirdEvent has copy, drop {
    owner: address,
    id: u64,
    power: u64,
    types: u8,
    block_time: u64,
    reward: u64,
    hunt_id: u128,
    nonce: u128,
}

// ----- Functions -----

fun init(bird: BIRD, ctx: &mut tx_context::TxContext) {
    let admin_cap = AdminCap { id: object::new(ctx) };
    transfer::public_transfer(admin_cap, tx_context::sender(ctx));

    let bird_vault = BirdVault {
        id: object::new(ctx),
        validator: option::none<vector<u8>>(),
    };
    transfer::share_object(bird_vault);

    cap_vault::createVault<AdminCap>(ctx);
}

public fun feedWorm(
    signature: vector<u8>,
    payload: vector<u8>,
    bird_nft: BirdNFT,
    bird_vault: &mut BirdVault,
    user_archieve: &mut archieve::UserArchieve,
    version: &version::Version,
    ctx: &mut 0x2::tx_context::TxContext,
) {
    version::checkVersion(version, 1);
    archieve::verifySignature(
        signature,
        payload,
        &bird_vault.validator,
    );

    let mut bcs_payload = 0x2::bcs::new(payload);
    let power = 0x2::bcs::peel_u64(&mut bcs_payload);
    let nonce = 0x2::bcs::peel_u128(&mut bcs_payload);
    let worm_id = 0x2::bcs::peel_address(&mut bcs_payload);
    let sender = 0x2::tx_context::sender(ctx);

    assert!(sender == 0x2::bcs::peel_address(&mut bcs_payload), 8001);
    archieve::verUpdatePreyPegNonce(
        nonce,
        user_archieve,
    );

    assert!(power > 0, 8003);
    assert!(0x2::object::id_address<BirdNFT>(&bird_nft)
            == worm_id, 8004);

    nft::burn(bird_nft, ctx);

    let feed_worm_event = FeedWormEvent {
        owner: sender,
        bird_id: 0x2::bcs::peel_u64(&mut bcs_payload),
        power,
        req_id: 0x2::bcs::peel_u128(&mut bcs_payload),
        nonce,
        worm_id,
    };

    0x2::event::emit<FeedWormEvent>(feed_worm_event);
}

public fun preyBird(
    signature: vector<u8>,
    payload: vector<u8>,
    bird_vault: &mut BirdVault,
    user_archieve: &mut archieve::UserArchieve,
    version: &version::Version,
    ctx: &mut tx_context::TxContext,
) {
    version::checkVersion(version, 1);
    archieve::verifySignature(signature, payload, &bird_vault.validator);

    let mut bcs_payload = bcs::new(payload);
    let nonce = bcs::peel_u128(&mut bcs_payload);
    let power = bcs::peel_u64(&mut bcs_payload);
    let block_time = bcs::peel_u64(&mut bcs_payload);
    let reward = bcs::peel_u64(&mut bcs_payload);
    let sender = tx_context::sender(ctx);

    assert!(sender == bcs::peel_address(&mut bcs_payload), 8001);
    assert!(block_time > 0 && reward > 0, 8002);

    archieve::verUpdatePreyPegNonce(nonce, user_archieve);

    assert!(power > 0, 8003);

    let prey_bird_event = PreyBirdEvent {
        owner: sender,
        id: 0,
        power,
        types: bcs::peel_u8(&mut bcs_payload),
        block_time,
        reward,
        hunt_id: bcs::peel_u128(&mut bcs_payload),
        nonce,
    };

    event::emit<PreyBirdEvent>(prey_bird_event);
}

public fun claimPreyReward(
    signature: vector<u8>,
    message: vector<u8>,
    bird_vault: &mut BirdVault,
    user_archieve: &mut archieve::UserArchieve,
    version: &version::Version,
    ctx: &mut tx_context::TxContext,
) {
    version::checkVersion(version, 1);
    archieve::verifySignature(signature, message, &bird_vault.validator);

    let sender = tx_context::sender(ctx);
    let mut message_bcs = bcs::new(message);
    let nonce = bcs::peel_u128(&mut message_bcs);

    assert!(sender == bcs::peel_address(&mut message_bcs), 8001);

    archieve::verUpdatePreyPegNonce(nonce, user_archieve);

    let event = ClaimPreyRewardEvent {
        owner: sender,
        hunt_id: bcs::peel_u128(&mut message_bcs),
        nonce,
    };

    event::emit<ClaimPreyRewardEvent>(event);
}

public fun updateValidator(
    admin_cap: &AdminCap,
    new_validator: vector<u8>,
    bird_vault: &mut BirdVault,
    version: &version::Version,
) {
    version::checkVersion(version, 1);
    option::swap_or_fill(&mut bird_vault.validator, new_validator);
}
