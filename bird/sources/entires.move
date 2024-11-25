// Decompiled by SuiGPT
module Bird::entries {

    // ----- Use Statements -----

    use Bird::bird;
    use Archive::archieve;
    use Bird::version;
    use Nft::nft;

    // ----- Functions -----

    public entry fun claimPreyReward(
        prey_id: vector<u8>,
        hunter_id: vector<u8>,
        bird_vault: &mut bird::BirdVault,
        user_archieve: &mut archieve::UserArchieve,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        bird::claimPreyReward(
            prey_id,
            hunter_id,
            bird_vault,
            user_archieve,
            version,
            ctx
        );
    }

    public entry fun feedWorm(
        worm_type: vector<u8>,
        worm_data: vector<u8>,
        bird_nft: nft::BirdNFT,
        bird_vault: &mut bird::BirdVault,
        user_archieve: &mut archieve::UserArchieve,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        bird::feedWorm(
            worm_type,
            worm_data,
            bird_nft,
            bird_vault,
            user_archieve,
            version,
            ctx
        );
    }

    public entry fun migrateVersion(
        admin_cap: &version::VerAdminCap,
        version: &mut version::Version,
        new_version: u64
    ) {
        version::migrate(admin_cap, version, new_version);
    }

    public entry fun preyBird(
        bird_id: vector<u8>,
        prey_id: vector<u8>,
        bird_vault: &mut bird::BirdVault,
        user_archieve: &mut archieve::UserArchieve,
        version: &version::Version,
        ctx: &mut tx_context::TxContext
    ) {
        bird::preyBird(
            bird_id,
            prey_id,
            bird_vault,
            user_archieve,
            version,
            ctx
        );
    }

    public entry fun updateValidator(
        admin_cap: &bird::AdminCap,
        validator_data: vector<u8>,
        bird_vault: &mut bird::BirdVault,
        version: &version::Version
    ) {
        bird::updateValidator(
            admin_cap,
            validator_data,
            bird_vault,
            version
        );
    }
}