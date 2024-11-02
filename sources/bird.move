// Decompiled by SuiGPT
module birds::bird {

    // ----- Use Statements -----
    use sui::table;
    use std::type_name;
    use sui::coin::{Self, Coin};
    use sui::dynamic_field;
    use birds::cap_vault;
    use birds::version;
    use sui::ed25519;
    use sui::clock;
    use sui::bcs;
    use sui::event;
    use sui::sui::{SUI};

    // ----- public structs -----

    public struct AdminCap has store, key {
        id: object::UID,
    }

    public struct BIRD has drop {
        dummy_field: bool,
    }

    public struct BirdArchieve has store, key {
        id: object::UID,
        owner: address,
        last_time: u64,
        bird: BirdGhost,
        nonce: u128,
        bird_nft: option::Option<NFTLite>,
    }

    public struct BirdGhost has drop, store {
        amount: u64,
    }

    public struct BirdMineEvent has copy, drop {
        owner: address,
        amount: u64,
        timestamp: u64,
        types: u8,
    }

    public struct BirdReg has store, key {
        id: object::UID,
        egg_regs: table::Table<address, bool>,
    }

    public struct BirdStore has store, key {
        id: object::UID,
        validator: option::Option<vector<u8>>,
    }

    public struct CatchWormEvent has copy, drop {
        owner: address,
        worm_id: u64,
        timestamp: u64,
    }

    public struct ClaimPreyRewardEvent has copy, drop {
        owner: address,
        reward: u64,
    }

    public struct ClaimReferallRewardEvent has copy, drop {
        owner: address,
        reward: u64,
    }

    public struct DepositEvent has copy, drop {
        from: address,
        amount: u64,
        to: address,
        type_token: type_name::TypeName,
        timestamp: u64,
    }

    public struct FeedWormEvent has copy, drop {
        owner: address,
        bird_id: u64,
        power: u64,
    }

    public struct MineBird {
        types: u8,
        owner: address,
        amount: u64,
        nonce: u128,
    }

    public struct MineNFT has drop, store {
        owner: address,
        nft_type: u8,
        id_ext: vector<u8>,
        types: u8,
        value: u64,
        nonce: u128,
    }

    public struct NFTLite has drop, store {
        nft_type: u8,
        id: u64,
        mint_time: u64,
        last_time: u64,
        types: u8,
        power: u64,
        preying: bool,
        prey_reward: u64,
        prey_unblock_at: u64,
    }

    public struct NftMineEvent has copy, drop {
        owner: address,
        nft_type: u8,
        id_ext: vector<u8>,
        timestamp: u64,
        types: u8,
        value: u64,
    }

    public struct PreyBird has copy, store {
        owner: address,
        types: u8,
        power: u64,
        block_time: u64,
        reward: u64,
        nonce: u128,
    }

    public struct PreyBirdEvent has copy, drop {
        owner: address,
        id: u64,
        power: u64,
        block_time: u64,
        reward: u64,
    }

    public struct ReferallReward has copy, store {
        owner: address,
        reward: u64,
        nonce: u128,
    }

    public struct RewardClaimedEvent has copy, drop {
        owner: address,
        amount: u64,
        timestamp: u64,
        nonce: u128,
    }

    public struct RewardDepositEvent has copy, drop {
        owner: address,
        amount: u64,
        timestamp: u64,
    }

    public struct RewardEmergencyWithdrawEvent has copy, drop {
        owner: address,
        amount: u64,
        timestamp: u64,
    }

    public struct RewardPool<phantom T0> has store, key {
        id: object::UID,
        active: bool,
        coins: coin::Coin<T0>,
        reward_limit: u64,
    }

    public struct SkipEvent has copy, drop {
        owner: address,
        amount: u64,
        timestamp: u64,
    }

    public struct TreasureCap has store, key {
        id: object::UID,
    }

    public struct UpgradeEvent has copy, drop {
        owner: address,
        amount: u64,
        timestamp: u64,
    }

    public struct UserReward has drop, store {
        owner: address,
        pool: address,
        amount: u64,
        nonce: u128,
    }

    // ----- Functions -----

    fun addBird(
        archive: &mut BirdArchieve,
        bird_nft: NFTLite
    ) {
        assert!(!exist_bird(archive), 8014);
        option::fill(&mut archive.bird_nft, bird_nft);
    }

    fun addWorm(
        birdArchive: &mut BirdArchieve,
        worm_id: u64,
        worm_nft: NFTLite
    ) {
        assert!(!exist_worm(birdArchive, worm_id), 8015);
        dynamic_field::add<u64, NFTLite>(&mut birdArchive.id, worm_id, worm_nft);
    }

    fun borrowBirdMut(archive: &mut BirdArchieve): &mut NFTLite {
        option::borrow_mut(&mut archive.bird_nft)
    }

    fun borrowWormMut(
        bird_archive: &mut BirdArchieve,
        worm_id: u64
    ): &mut NFTLite {
        dynamic_field::borrow_mut<u64, NFTLite>(&mut bird_archive.id, worm_id)
    }

    fun exist_bird(archive: &BirdArchieve): bool {
        option::is_some<NFTLite>(&archive.bird_nft)
    }

    fun exist_worm(
        bird_archive: &BirdArchieve,
        worm_id: u64
    ): bool {
        dynamic_field::exists_<u64>(&bird_archive.id, worm_id)
    }

    fun init(
        bird: BIRD,
        ctx: &mut tx_context::TxContext
    ) {
        let admin_cap = AdminCap { id: object::new(ctx) };
        transfer::public_transfer(admin_cap, ctx.sender());

        let treasure_cap = TreasureCap { id: object::new(ctx) };
        transfer::public_transfer(treasure_cap, ctx.sender());

        let bird_store = BirdStore {
            id: object::new(ctx),
            validator: option::none(),
        };
        transfer::share_object(bird_store);

        let bird_reg = BirdReg {
            id: object::new(ctx),
            egg_regs: table::new(ctx),
        };
        transfer::share_object(bird_reg);

        cap_vault::createVault<AdminCap>(ctx);
        cap_vault::createVault<TreasureCap>(ctx);
        cap_vault::createVault<version::VAdminCap>(ctx);
    }

    fun verifySignature(
        signature: vector<u8>,
        message: vector<u8>,
        bird_store: &BirdStore
    ) {
        assert!(option::is_some(&bird_store.validator), 8010);
        assert!(
            ed25519::ed25519_verify(
                &signature,
                option::borrow(&bird_store.validator),
                &message
            ),
            8000
        );
    }

    public fun updateValidator(
        admin_cap: &AdminCap,
        new_validator: vector<u8>,
        bird_store: &mut BirdStore,
        version: &version::Version
    ) {
        version::checkVersion(version, 1);
        option::swap_or_fill(&mut bird_store.validator, new_validator);
    }

    public fun register(
        bird_reg: &mut BirdReg,
        clock: &clock::Clock,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        version::checkVersion(version, 1);
        let sender = ctx.sender();
        assert!(
            !table::contains<address, bool>(&bird_reg.egg_regs, sender),
            8005
        );
        let bird_ghost = BirdGhost { amount: 0 };
        let bird_archieve = BirdArchieve {
            id: object::new(ctx),
            owner: sender,
            last_time: clock::timestamp_ms(clock),
            bird: bird_ghost,
            nonce: 0,
            bird_nft: option::none<NFTLite>(),
        };
        transfer::public_transfer(bird_archieve, sender);
        table::add(&mut bird_reg.egg_regs, sender, true);
    }

    public fun mineBird(
        signature: vector<u8>,
        payload: vector<u8>,
        bird_store: &mut BirdStore,
        bird_archive: &mut BirdArchieve,
        clock: &clock::Clock,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        version::checkVersion(version, 1);
        verifySignature(signature, payload, bird_store);

        let mut payload_bcs = bcs::new(payload);
        let bird_type = bcs::peel_u8(&mut payload_bcs);
        let owner = bcs::peel_address(&mut payload_bcs);
        let amount = bcs::peel_u64(&mut payload_bcs);
        let nonce = bcs::peel_u128(&mut payload_bcs);

        assert!(bird_type <= 1, 8004);
        assert!(nonce > bird_archive.nonce, 8003);
        assert!(owner == ctx.sender(), 8001);
        assert!(amount > 0, 8002);

        let timestamp = clock::timestamp_ms(clock);
        bird_archive.bird.amount = bird_archive.bird.amount + amount;
        bird_archive.nonce = nonce;
        bird_archive.last_time = timestamp;

        let bird_mine_event = BirdMineEvent {
            owner,
            amount,
            timestamp,
            types: bird_type,
        };

        event::emit<BirdMineEvent>(bird_mine_event);
    }

    public fun mineNft(
        signature: vector<u8>,
        payload: vector<u8>,
        bird_store: &mut BirdStore,
        bird_archive: &mut BirdArchieve,
        clock: &clock::Clock,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        version::checkVersion(version, 1);
        verifySignature(signature, payload, bird_store);
        
        let sender = ctx.sender();
        let timestamp = clock::timestamp_ms(clock);
        let mut bcs_payload = bcs::new(payload);
        let nft_type = bcs::peel_u8(&mut bcs_payload);
        let nonce = bcs::peel_u128(&mut bcs_payload);
        
        assert!(nft_type >= 0 && nft_type <= 1, 8004);
        assert!(nonce > bird_archive.nonce, 8003);
        assert!(bcs::peel_address(&mut bcs_payload) == sender, 8001);
        
        bird_archive.nonce = nonce;
        bird_archive.last_time = timestamp;
        
        let nft_mine_event = NftMineEvent {
            owner: sender,
            nft_type,
            id_ext: bcs::peel_vec_u8(&mut bcs_payload),
            timestamp,
            types: bcs::peel_u8(&mut bcs_payload),
            value: bcs::peel_u64(&mut bcs_payload),
        };
        
        event::emit(nft_mine_event);
    }

    public fun createRewardPool<T>(
        admin_cap: &AdminCap,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        version::checkVersion(version, 1);
        let reward_pool = RewardPool<T> {
            id: object::new(ctx),
            active: true,
            coins: coin::zero<T>(ctx),
            reward_limit: 0,
        };
        transfer::share_object(reward_pool);
    }

    public fun configRewardPool<T>(
        admin_cap: &AdminCap,
        reward_pool: &mut RewardPool<T>,
        is_active: bool,
        reward_limit: u64,
        version: &version::Version
    ) {
        version::checkVersion(version, 1);
        reward_pool.active = is_active;
        reward_pool.reward_limit = reward_limit;
    }

    public fun depositReward<T>(
        reward_coin: coin::Coin<T>,
        reward_pool: &mut RewardPool<T>,
        version: &version::Version,
        clock: &clock::Clock,
        ctx: &tx_context::TxContext
    ) {
        version::checkVersion(version, 1);
        let coin_value = reward_coin.value();

        coin::join(&mut reward_pool.coins, reward_coin);
        let deposit_event = RewardDepositEvent {
            owner: ctx.sender(),
            amount: coin_value,
            timestamp: clock::timestamp_ms(clock),
        };
        event::emit(deposit_event);
    }

    public fun emergencyRewardWithdraw<T>(
        cap: &TreasureCap,
        reward_pool: &mut RewardPool<T>,
        version: &version::Version,
        clock: &clock::Clock,
        ctx: &mut tx_context::TxContext
    ) {
        version::checkVersion(version, 1);
        let owner = ctx.sender();
        let amount = coin::value(&reward_pool.coins);
        transfer::public_transfer(
            coin::split(&mut reward_pool.coins, amount, ctx),
            owner
        );
        event::emit<RewardEmergencyWithdrawEvent>(RewardEmergencyWithdrawEvent {
            owner,
            amount,
            timestamp: clock::timestamp_ms(clock),
        });
    }

    public fun claimReward<T>(
        signature: vector<u8>,
        payload: vector<u8>,
        reward_pool: &mut RewardPool<T>,
        bird_store: &mut BirdStore,
        bird_archive: &mut BirdArchieve,
        version: &version::Version,
        clock: &clock::Clock,
        ctx: &mut tx_context::TxContext
    ) {
        version::checkVersion(version, 1);
        assert!(reward_pool.active, 8006);
        verifySignature(signature, payload, bird_store);

        let mut payload_bytes = bcs::new(payload);
        let owner = bcs::peel_address(&mut payload_bytes);
        let amount = bcs::peel_u64(&mut payload_bytes);
        let nonce = bcs::peel_u128(&mut payload_bytes);

        assert!(ctx.sender() == owner, 8001);
        assert!(object::id_address(reward_pool) == bcs::peel_address(&mut payload_bytes), 8008);
        assert!(nonce > bird_archive.nonce, 8003);

        let timestamp = clock::timestamp_ms(clock);
        assert!(reward_pool.reward_limit == 0 || reward_pool.reward_limit >= amount, 8007);

        bird_archive.nonce = nonce;
        bird_archive.last_time = timestamp;

        transfer::public_transfer(
            coin::split(&mut reward_pool.coins, amount, ctx),
            owner
        );

        let event = RewardClaimedEvent {
            owner,
            amount,
            timestamp,
            nonce,
        };

        event::emit(event);
    }

    public fun sponsor_gas(
        sui_coin: &mut Coin<SUI>,
        recipients: vector<address>,
        amount_per_recipient: u64,
        ctx: &mut tx_context::TxContext
    ) {
        assert!(
            vector::length(&recipients) > 0 &&
            amount_per_recipient > 0 &&
            coin::value(sui_coin) >= vector::length(&recipients) * amount_per_recipient,
            8009
        );

        let mut num_recipients = vector::length(&recipients);
        while (num_recipients > 0) {
            let index = num_recipients - 1;
            num_recipients = index;
            let recipient = *vector::borrow(&recipients, index);
            transfer::public_transfer(
                coin::split(  sui_coin, amount_per_recipient, ctx),
                recipient
            );
        };
        // if(sui_coin.value() > 0) {
        // transfer::public_transfer(sui_coin, ctx.sender());
        // }
    }

    public fun feedWorm(
        signature: vector<u8>,
        payload: vector<u8>,
        bird_store: &mut BirdStore,
        bird_archive: &mut BirdArchieve,
        clock: &clock::Clock,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        version::checkVersion(version, 1);
        let current_time = clock::timestamp_ms(clock);
        verifySignature(signature, payload, bird_store);
        
        let mut bcs_payload = bcs::new(payload);
        let power = bcs::peel_u64(&mut bcs_payload);
        let new_nonce = bcs::peel_u128(&mut bcs_payload);
        let sender = ctx.sender();
        
        assert!(sender == bcs::peel_address(&mut bcs_payload), 8001);
        assert!(new_nonce > bird_archive.nonce, 8003);
        assert!(power > 0, 8012);
        
        bird_archive.nonce = new_nonce;
        bird_archive.last_time = current_time;
        
        if (exist_bird(bird_archive)) {
            let bird = borrowBirdMut(bird_archive);
            bird.power = bird.power + power;
            bird.last_time = current_time;
        };
        
        let feed_event = FeedWormEvent {
            owner: sender,
            bird_id: bcs::peel_u64(&mut bcs_payload),
            power: power,
        };
        
        event::emit(feed_event);
    }

    public fun preyBird(
        signature: vector<u8>,
        payload: vector<u8>,
        bird_store: &mut BirdStore,
        bird_archive: &mut BirdArchieve,
        clock: &clock::Clock,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        version::checkVersion(version, 1);
        let current_time = clock::timestamp_ms(clock);
        verifySignature(signature, payload, bird_store);
        
        let mut payload_bcs = bcs::new(payload);
        let power = bcs::peel_u64(&mut payload_bcs);
        let block_time = bcs::peel_u64(&mut payload_bcs);
        let reward = bcs::peel_u64(&mut payload_bcs);
        let nonce = bcs::peel_u128(&mut payload_bcs);
        let sender = ctx.sender();
        
        assert!(sender == bcs::peel_address(&mut payload_bcs), 8001);
        assert!(nonce > bird_archive.nonce, 8003);
        assert!(block_time > 0 && reward > 0, 8002);
        assert!(power > 0, 8012);
        
        bird_archive.nonce = nonce;
        bird_archive.last_time = current_time;
        
        if (!exist_bird(bird_archive)) {
            let new_bird = NFTLite {
                nft_type: 1,
                id: 0,
                mint_time: current_time,
                last_time: current_time,
                types: bcs::peel_u8(&mut payload_bcs),
                power,
                preying: true,
                prey_reward: reward,
                prey_unblock_at: current_time + block_time,
            };
            addBird(bird_archive, new_bird);
        } else {
            let bird = borrowBirdMut(bird_archive);
            let can_prey = if (!bird.preying) {
                true
            } else {
                bird.preying && bird.prey_unblock_at <= current_time
            };
            assert!(can_prey, 8013);
            
            if (!bird.preying || bird.prey_unblock_at <= current_time) {
                claimPreyReward(bird_archive, clock, version, ctx);
                let bird_mut = borrowBirdMut(bird_archive);
                bird_mut.preying = true;
                bird_mut.power = power;
                bird_mut.prey_reward = reward;
                bird_mut.prey_unblock_at = current_time + block_time;
                bird_mut.last_time = current_time;
            } else {
                bird.preying = true;
                bird.power = power;
                bird.prey_reward = reward;
                bird.prey_unblock_at = current_time + block_time;
                bird.last_time = current_time;
            }
        };
        
        let prey_event = PreyBirdEvent {
            owner: sender,
            id: 0,
            power,
            block_time,
            reward,
        };
        event::emit(prey_event);
    }

    public fun claimPreyReward(
        bird_archive: &mut BirdArchieve,
        clock: &clock::Clock,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        version::checkVersion(version, 1);
        let current_time = clock::timestamp_ms(clock);
        
        if (exist_bird(bird_archive)) {
            let bird = borrowBirdMut(bird_archive);
            assert!(bird.preying && bird.prey_unblock_at <= current_time, 8013);
            
            let prey_reward = bird.prey_reward;
            bird.preying = false;
            bird.prey_reward = 0;
            bird.prey_unblock_at = 0;
            bird.last_time = current_time;
            
            bird_archive.bird.amount = bird_archive.bird.amount + prey_reward;
            bird_archive.last_time = current_time;
            
            let event = ClaimPreyRewardEvent {
                owner: ctx.sender(),
                reward: prey_reward,
            };
            event::emit(event);
        };
    }

    public fun claimReferallReward(
        signature: vector<u8>,
        payload: vector<u8>,
        bird_store: &mut BirdStore,
        bird_archive: &mut BirdArchieve,
        clock: &clock::Clock,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        version::checkVersion(version, 1);
        verifySignature(signature, payload, bird_store);

        let mut bcs_payload = bcs::new(payload);
        let reward_amount = bcs::peel_u64(&mut bcs_payload);
        let new_nonce = bcs::peel_u128(&mut bcs_payload);
        let sender = ctx.sender();

        assert!(sender == bcs::peel_address(&mut bcs_payload), 8001);
        assert!(new_nonce > bird_archive.nonce, 8003);

        bird_archive.nonce = new_nonce;
        bird_archive.last_time = clock::timestamp_ms(clock);
        bird_archive.bird.amount = bird_archive.bird.amount + reward_amount;

        let event = ClaimReferallRewardEvent {
            owner: sender,
            reward: reward_amount,
        };

        event::emit(event);
    }

    public fun deposit<T>(
        recipient: address,
        coin: coin::Coin<T>,
        clock: &clock::Clock,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        version::checkVersion(version, 1);
        let coin_value = coin::value(&coin);
        assert!(coin_value > 0, 8018);
        transfer::public_transfer(coin, recipient);
        let deposit_event = DepositEvent {
            from: ctx.sender(),
            amount: coin_value,
            to: recipient,
            type_token: type_name::get<T>(),
            timestamp: clock::timestamp_ms(clock),
        };
        event::emit(deposit_event);
    }

    public fun upgrade(
        signature: vector<u8>,
        payload: vector<u8>,
        bird_store: &mut BirdStore,
        bird_archive: &mut BirdArchieve,
        clock: &clock::Clock,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        version::checkVersion(version, 1);
        verifySignature(signature, payload, bird_store);

        let mut payload_bcs = bcs::new(payload);
        let owner = bcs::peel_address(&mut payload_bcs);
        let amount = bcs::peel_u64(&mut payload_bcs);
        let nonce = bcs::peel_u128(&mut payload_bcs);

        assert!(nonce > bird_archive.nonce, 8003);
        assert!(owner == ctx.sender(), 8001);
        assert!(amount > 0, 8002);

        let timestamp = clock::timestamp_ms(clock);
        assert!(bird_archive.bird.amount >= amount, 8018);

        bird_archive.bird.amount = bird_archive.bird.amount - amount;
        bird_archive.nonce = nonce;
        bird_archive.last_time = timestamp;

        let upgrade_event = UpgradeEvent {
            owner,
            amount,
            timestamp,
        };

        event::emit(upgrade_event);
    }

    public fun skip(
        signature: vector<u8>,
        payload: vector<u8>,
        bird_store: &mut BirdStore,
        bird_archive: &mut BirdArchieve,
        clock: &clock::Clock,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        version::checkVersion(version, 1);
        verifySignature(signature, payload, bird_store);

        let mut payload_bcs = bcs::new(payload);
        let owner = bcs::peel_address(&mut payload_bcs);
        let amount = bcs::peel_u64(&mut payload_bcs);
        let nonce = bcs::peel_u128(&mut payload_bcs);

        assert!(nonce > bird_archive.nonce, 8003);
        assert!(owner == ctx.sender(), 8001);
        assert!(amount > 0, 8002);

        let timestamp = clock::timestamp_ms(clock);
        assert!(bird_archive.bird.amount >= amount, 8018);

        bird_archive.bird.amount = bird_archive.bird.amount - amount;
        bird_archive.nonce = nonce;
        bird_archive.last_time = timestamp;

        let skip_event = SkipEvent {
            owner,
            amount,
            timestamp,
        };

        event::emit(skip_event);
    }

    public fun catchWorm(
        signature: vector<u8>,
        payload: vector<u8>,
        bird_store: &mut BirdStore,
        bird_archive: &mut BirdArchieve,
        clock: &clock::Clock,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        version::checkVersion(version, 1);
        verifySignature(signature, payload, bird_store);

        let mut payload_bcs = bcs::new(payload);
        let owner = bcs::peel_address(&mut payload_bcs);
        let worm_id = bcs::peel_u64(&mut payload_bcs);
        let nonce = bcs::peel_u128(&mut payload_bcs);

        assert!(nonce > bird_archive.nonce, 8003);
        assert!(owner == ctx.sender(), 8001);
        assert!(worm_id >= 0, 8017);

        let timestamp = clock::timestamp_ms(clock);
        bird_archive.nonce = nonce;
        bird_archive.last_time = timestamp;

        let event = CatchWormEvent {
            owner,
            worm_id,
            timestamp,
        };

        event::emit<CatchWormEvent>(event);
    }

    public fun infoBirdGhost(
        bird_archive: &BirdArchieve
    ): (address, u64, u128) {
        (bird_archive.owner, bird_archive.bird.amount, bird_archive.nonce)
    }
}