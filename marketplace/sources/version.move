// // Decompiled by SuiGPT
// module 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::version {

//     // ----- Use Statements -----

//     use sui::object;
//     use sui::tx_context;
//     use sui::transfer;
//     use 0x38dba0f0cf9a80c9b9debf580c82f89bb0de4577e6fb448b3ba2ee9e05d539bc::cap_vault;

//     // ----- Structs -----

//     struct VERSION has drop {
//         dummy_field: bool,
//     }

//     struct VerAdminCap has store, key {
//         id: object::UID,
//     }

//     struct Version has store, key {
//         id: object::UID,
//         version: u64,
//         admin: object::ID,
//     }

//     // ----- Functions -----

//     fun init(
//         version: VERSION,
//         ctx: &mut tx_context::TxContext
//     ) {
//         let admin_cap = VerAdminCap {
//             id: object::new(ctx)
//         };
//         transfer::public_transfer(admin_cap, tx_context::sender(ctx));

//         let version_object = Version {
//             id: object::new(ctx),
//             version: 1,
//             admin: object::id(&admin_cap),
//         };
//         transfer::public_share_object(version_object);

//         cap_vault::createVault<VerAdminCap>(ctx);
//     }

//     public fun checkVersion(
//         version: &Version,
//         input_version: u64
//     ) {
//         assert!(input_version >= version.version, 2001);
//     }

//     public fun migrate(
//         admin_cap: &VerAdminCap,
//         version: &mut Version,
//         new_version: u64
//     ) {
//         assert!(
//             object::id(admin_cap) == version.admin,
//             2002
//         );
//         assert!(
//             new_version > version.version,
//             2001
//         );
//         version.version = new_version;
//     }
// }