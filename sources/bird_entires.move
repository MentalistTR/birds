// Decompiled by SuiGPT
module birds::bird_entries {

    // ----- Use Statements -----

    use birds::bird::{Self};
    use sui::clock;
    use birds::version;
    use birds::cap_vault;
    use sui::coin;
    use sui::sui::SUI;
    use sui::coin::{Coin};

    // ----- Functions -----

    public entry fun catchWorm(
        bird_id: vector<u8>,
        worm_id: vector<u8>,
        bird_store: &mut bird::BirdStore,
        bird_archive: &mut bird::BirdArchieve,
        clock: &clock::Clock,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        bird::catchWorm(
            bird_id, worm_id, bird_store, bird_archive, clock, version, ctx
        );
    }

    public entry fun claimPreyReward(
        bird_archive: &mut bird::BirdArchieve,
        clock: &clock::Clock,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        bird::claimPreyReward(bird_archive, clock, version, ctx);
    }

    public entry fun claimReferallReward(
        referrer: vector<u8>,
        referee: vector<u8>,
        bird_store: &mut bird::BirdStore,
        bird_archieve: &mut bird::BirdArchieve,
        clock: &clock::Clock,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        bird::claimReferallReward(
            referrer, referee, bird_store, bird_archieve, clock, version, ctx
        );
    }

    public entry fun claimReward<T>(
        user_id: vector<u8>,
        reward_id: vector<u8>,
        reward_pool: &mut bird::RewardPool<T>,
        bird_store: &mut bird::BirdStore,
        bird_archive: &mut bird::BirdArchieve,
        version: &version::Version,
        clock: &clock::Clock,
        ctx: &mut tx_context::TxContext
    ) {
        bird::claimReward<T>(
            user_id,
            reward_id,
            reward_pool,
            bird_store,
            bird_archive,
            version,
            clock,
            ctx
        );
    }

    public entry fun claim_cap<T: store + key>(
        cap_vault: &mut cap_vault::CapVault<T>,
        ctx: &tx_context::TxContext
    ) {
        let cap = cap_vault::claim_cap(cap_vault, ctx);
        transfer::public_transfer(cap, ctx.sender());
    }

    public entry fun configRewardPool<T>(
        admin_cap: &bird::AdminCap,
        reward_pool: &mut bird::RewardPool<T>,
        is_active: bool,
        reward_amount: u64,
        version: &version::Version
    ) {
        bird::configRewardPool(
            admin_cap,
            reward_pool,
            is_active,
            reward_amount,
            version
        );
    }

    public entry fun createRewardPool<T>(
        admin_cap: &bird::AdminCap,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        bird::createRewardPool<T>(admin_cap, version, ctx);
    }

    public entry fun deposit<T>(
        recipient: address,
        coin: coin::Coin<T>,
        clock: &clock::Clock,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        bird::deposit<T>(recipient, coin, clock, version, ctx);
    }

    public entry fun depositReward<T>(
        reward: coin::Coin<T>,
        reward_pool: &mut bird::RewardPool<T>,
        version: &version::Version,
        clock: &clock::Clock,
        ctx: &tx_context::TxContext
    ) {
        bird::depositReward(reward, reward_pool, version, clock, ctx);
    }

    public entry fun emergencyRewardWithdraw<T>(
        treasure_cap: &bird::TreasureCap,
        reward_pool: &mut bird::RewardPool<T>,
        version: &version::Version,
        clock: &clock::Clock,
        ctx: &mut tx_context::TxContext
    ) {
        bird::emergencyRewardWithdraw<T>(
            treasure_cap,
            reward_pool,
            version,
            clock,
            ctx
        );
    }

    public entry fun infoBirdGhost(
        bird_archieve: &bird::BirdArchieve
    ): (address, u64, u128) {
        bird::infoBirdGhost(bird_archieve)
    }

    public entry fun mineBird(
        bird_id: vector<u8>,
        bird_data: vector<u8>,
        bird_store: &mut bird::BirdStore,
        bird_archive: &mut bird::BirdArchieve,
        clock: &clock::Clock,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        bird::mineBird(
            bird_id,
            bird_data,
            bird_store,
            bird_archive,
            clock,
            version,
            ctx
        );
    }

    public entry fun preyBird(
        bird_id: vector<u8>,
        prey_id: vector<u8>,
        bird_store: &mut bird::BirdStore,
        bird_archive: &mut bird::BirdArchieve,
        clock: &clock::Clock,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        bird::preyBird(
            bird_id, prey_id, bird_store, bird_archive, clock, version, ctx
        );
    }

    public entry fun register(
        bird_reg: &mut bird::BirdReg,
        clock: &clock::Clock,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        bird::register(bird_reg, clock, version, ctx);
    }

    public entry fun revoke_cap<T: store + key>(
        cap_vault: &mut cap_vault::CapVault<T>,
        ctx: &tx_context::TxContext
    ) {
        let cap = cap_vault::revoke_cap(cap_vault, ctx);
        transfer::public_transfer(cap, ctx.sender());
    }

    public entry fun skip(
        arg0: vector<u8>,
        arg1: vector<u8>,
        bird_store: &mut bird::BirdStore,
        bird_archive: &mut bird::BirdArchieve,
        clock: &clock::Clock,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        bird::skip(
            arg0, 
            arg1, 
            bird_store, 
            bird_archive, 
            clock, 
            version, 
            ctx
        );
    }

    public entry fun sponsor_gas(
        coin: &mut Coin<SUI>,
        recipients: vector<address>,
        amount: u64,
        ctx: &mut tx_context::TxContext
    ) {
        bird::sponsor_gas(coin, recipients, amount, ctx);
    }

    public entry fun transfer_cap<T: store + key>(
        cap: T,
        recipient: address,
        cap_vault: &mut cap_vault::CapVault<T>,
        ctx: &mut tx_context::TxContext
    ) {
        cap_vault::transfer_cap(cap, recipient, cap_vault, ctx);
    }

    public entry fun updateValidator(
        admin_cap: &bird::AdminCap,
        validator_data: vector<u8>,
        bird_store: &mut bird::BirdStore,
        version: &mut version::Version
    ) {
        bird::updateValidator(admin_cap, validator_data, bird_store, version);
    }

    public entry fun upgrade(
        param1: vector<u8>,
        param2: vector<u8>,
        bird_store: &mut bird::BirdStore,
        bird_archive: &mut bird::BirdArchieve,
        clock: &clock::Clock,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        bird::upgrade(
            param1, param2, bird_store, bird_archive, clock, version, ctx
        );
    }

    public fun feedWorm(
        worm_id: vector<u8>,
        bird_id: vector<u8>,
        bird_store: &mut bird::BirdStore,
        bird_archive: &mut bird::BirdArchieve,
        clock: &clock::Clock,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        bird::feedWorm(
            worm_id,
            bird_id,
            bird_store,
            bird_archive,
            clock,
            version,
            ctx
        );
    }
}