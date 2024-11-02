// Decompiled by SuiGPT
module birds::version {

    // ----- Use Statements -----
    
    // ----- Structs -----

    public struct VAdminCap has store, key {
        id: object::UID,
    }

    public struct VERSION has drop {
        dummy_field: bool,
    }

    public struct Version has store, key {
        id: object::UID,
        version: u64,
        admin: object::ID,
    }

    // ----- Functions -----

    fun init(
        _version: VERSION,
        ctx: &mut tx_context::TxContext
    ) {
        let admin_cap = VAdminCap { id: object::new(ctx) };
        // set the admin_cap id
        let admin_id = object::id(&admin_cap);

        transfer::transfer(admin_cap, ctx.sender());

        let version_object = Version {
            id: object::new(ctx),
            version: 1,
            admin: admin_id,
        };

        transfer::share_object(version_object);
    }

    public entry fun migrate(
        admin_cap: &VAdminCap,
        version: &mut Version,
        new_version: u64
    ) {
        assert!(object::id(admin_cap) == version.admin, 1002);
        assert!(new_version > version.version, 1001);
        version.version = new_version;
    }

    public fun checkVersion(
        version_struct: &Version,
        version_number: u64
    ) {
        assert!(version_number == version_struct.version, 1001);
    }
}