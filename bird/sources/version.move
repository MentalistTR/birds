// Decompiled by SuiGPT
module Bird::bird_version {

    // ----- Use Statements -----

    use Archive::cap_vault;

    // ----- Structs -----

    public struct BIRD_VERSION has drop {
        dummy_field: bool,
    }

    public struct VerAdminCap has store, key {
        id: object::UID,
    }

    public struct Version has store, key {
        id: object::UID,
        version: u64,
        admin: object::ID,
    }

    // ----- Functions -----

    fun init(
        version: BIRD_VERSION,
        ctx: &mut tx_context::TxContext
    ) {
        let admin_cap = VerAdminCap { id: object::new(ctx) };
        let admin_id = object::id(&admin_cap);

        transfer::public_transfer(admin_cap, tx_context::sender(ctx));

        let version_object = Version {
            id: object::new(ctx),
            version: 1,
            admin: admin_id
        };
        transfer::public_share_object(version_object);

        cap_vault::createVault<VerAdminCap>(ctx);
    }

    public fun checkVersion(
        version: &Version,
        required_version: u64
    ) {
        assert!(required_version >= version.version, 2001);
    }

    public fun migrate(
        admin_cap: &VerAdminCap,
        version: &mut Version,
        new_version: u64
    ) {
        assert!(
            object::id(admin_cap) == version.admin,
            2002
        );
        assert!(
            new_version > version.version,
            2001
        );
        version.version = new_version;
    }
}