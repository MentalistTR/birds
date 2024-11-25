// // Decompiled by SuiGPT
// module 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::clt {

//     // ----- Use Statements -----

//     use sui::object;
//     use std::ascii;
//     use sui::coin;
//     use std::option;
//     use sui::tx_context;
//     use 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::version;
//     use sui::transfer;
//     use 0x38dba0f0cf9a80c9b9debf580c82f89bb0de4577e6fb448b3ba2ee9e05d539bc::cap_vault;
//     use 0x38dba0f0cf9a80c9b9debf580c82f89bb0de4577e6fb448b3ba2ee9e05d539bc::archieve;
//     use sui::clock;
//     use sui::balance;
//     use sui::bcs;
//     use std::type_name;
//     use sui::event;

//     // ----- Structs -----

//     struct CLT has drop {
//         dummy_field: bool,
//     }

//     struct CltAdminCap has store, key {
//         id: object::UID,
//     }

//     struct CltDeposited has copy, drop {
//         token: ascii::String,
//         owner: address,
//         nonce: u128,
//         balance: u64,
//         total_deposit: u64,
//     }

//     struct CltVault<phantom T0> has store, key {
//         id: object::UID,
//         owner: object::ID,
//         treasureCap: coin::TreasuryCap<T0>,
//         metadata: coin::CoinMetadata<T0>,
//         validator: option::Option<vector<u8>>,
//         burn_nonce: u128,
//     }

//     struct CltWithdrawn has copy, drop {
//         token: ascii::String,
//         owner: address,
//         nonce: u128,
//         balance: u64,
//     }

//     struct DepositProof {
//         owner: address,
//         balance: u64,
//     }

//     // ----- Functions -----

//     fun init(
//         clt: CLT,
//         ctx: &mut tx_context::TxContext
//     ) {
//     }

//     fun treasureMut<T>(
//         vault: &mut CltVault<T>
//     ): &mut coin::TreasuryCap<T> {
//         &mut vault.treasureCap
//     }

//     public fun createClt<T>(
//         treasury_cap: coin::TreasuryCap<T>,
//         metadata: coin::CoinMetadata<T>,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ): CltAdminCap {
//         version::checkVersion(version, 1);

//         let admin_cap = CltAdminCap {
//             id: object::new(ctx)
//         };

//         let vault = CltVault<T> {
//             id: object::new(ctx),
//             owner: object::id(&admin_cap),
//             treasureCap: treasury_cap,
//             metadata,
//             validator: option::none<vector<u8>>(),
//             burn_nonce: 0,
//         };

//         transfer::public_share_object(vault);
//         cap_vault::createVault<CltAdminCap>(ctx);

//         admin_cap
//     }

//     public fun setValidator<T>(
//         admin_cap: &CltAdminCap,
//         validator: vector<u8>,
//         vault: &mut CltVault<T>,
//         version: &version::Version
//     ) {
//         version::checkVersion(version, 1);
//         assert!(vault.owner == object::id(admin_cap), 1001);
//         option::swap_or_fill(&mut vault.validator, validator);
//     }

//     public fun depositToken<T>(
//         signature: vector<u8>,
//         payload: vector<u8>,
//         vault: &mut CltVault<T>,
//         user_archieve: &mut archieve::UserArchieve,
//         version: &version::Version,
//         clock: &clock::Clock,
//         ctx: &mut tx_context::TxContext
//     ): (balance::Balance<T>, DepositProof, u64) {
//         version::checkVersion(version, 1);
//         archieve::verifySignature(signature, payload, &vault.validator);

//         let sender = tx_context::sender(ctx);
//         let bcs_payload = bcs::new(payload);
//         let balance = bcs::peel_u64(&mut bcs_payload);
//         let nonce = bcs::peel_u128(&mut bcs_payload);

//         assert!(bcs::peel_address(&mut bcs_payload) == sender, 1001);
//         assert!(balance > 0, 1002);
//         assert!(bcs::peel_u64(&mut bcs_payload) > clock::timestamp_ms(clock), 1004);

//         archieve::verUpdateTokenPegNonce(nonce, user_archieve);

//         let deposit_proof = DepositProof {
//             owner: sender,
//             balance,
//         };

//         let total_deposit = archieve::increaseTotalDeposit(balance, user_archieve);

//         let clt_deposited_event = CltDeposited {
//             token: type_name::into_string(type_name::get<T>()),
//             owner: sender,
//             nonce,
//             balance,
//             total_deposit,
//         };

//         event::emit(clt_deposited_event);

//         let minted_balance = coin::mint_balance(treasureMut<T>(vault), balance);
//         let timestamp = bcs::peel_u64(&mut bcs_payload);

//         (minted_balance, deposit_proof, timestamp)
//     }

//     public fun depositTokenForOrder<T>(
//         signature: vector<u8>,
//         message: vector<u8>,
//         vault: &mut CltVault<T>,
//         user_archieve: &mut archieve::UserArchieve,
//         version: &version::Version,
//         clock: &clock::Clock,
//         ctx: &mut tx_context::TxContext
//     ): (balance::Balance<T>, DepositProof, u128, u64) {
//         version::checkVersion(version, 1);
//         archieve::verifySignature(signature, message, &vault.validator);

//         let sender = tx_context::sender(ctx);
//         let bcs_message = bcs::new(message);
//         let balance = bcs::peel_u64(&mut bcs_message);
//         let nonce = bcs::peel_u128(&mut bcs_message);
//         let peeled_address = bcs::peel_address(&mut bcs_message);
//         let expiration_time = bcs::peel_u64(&mut bcs_message);
//         let current_time = clock::timestamp_ms(clock);

//         assert!(peeled_address == sender, 1001);
//         assert!(balance > 0, 1002);
//         assert!(expiration_time > current_time, 1004);

//         archieve::verUpdateTokenPegNonce(nonce, user_archieve);

//         let deposit_proof = DepositProof {
//             owner: sender,
//             balance,
//         };

//         let total_deposit = archieve::increaseTotalDeposit(balance, user_archieve);

//         let clt_deposited = CltDeposited {
//             token: type_name::into_string((type_name::get<T>())),
//             owner: sender,
//             nonce,
//             balance,
//             total_deposit,
//         };

//         event::emit(clt_deposited);

//         let minted_balance = coin::mint_balance(
//             treasureMut(vault),
//             balance
//         );

//         let peeled_u128 = bcs::peel_u128(&mut bcs_message);
//         let peeled_u64 = bcs::peel_u64(&mut bcs_message);

//         (minted_balance, deposit_proof, peeled_u128, peeled_u64)
//     }

//     public fun depositTokenForOrderIds<T>(
//         signature: vector<u8>,
//         payload: vector<u8>,
//         vault: &mut CltVault<T>,
//         user_archieve: &mut archieve::UserArchieve,
//         version: &version::Version,
//         clock: &clock::Clock,
//         ctx: &mut tx_context::TxContext
//     ): (balance::Balance<T>, DepositProof, vector<u128>, u64) {
//         version::checkVersion(version, 1);
//         archieve::verifySignature(signature, payload, &vault.validator);
        
//         let sender = tx_context::sender(ctx);
//         let bcs_payload = bcs::new(payload);
//         let balance = bcs::peel_u64(&mut bcs_payload);
//         let nonce = bcs::peel_u128(&mut bcs_payload);
//         let peeled_address = bcs::peel_address(&mut bcs_payload);
//         let expiration = bcs::peel_u64(&mut bcs_payload);
//         let timestamp = clock::timestamp_ms(clock);

//         assert!(peeled_address == sender, 1001);
//         assert!(balance > 0, 1002);
//         assert!(expiration > timestamp, 1004);

//         archieve::verUpdateTokenPegNonce(nonce, user_archieve);

//         let deposit_proof = DepositProof {
//             owner: sender,
//             balance,
//         };

//         let total_deposit = archieve::increaseTotalDeposit(balance, user_archieve);

//         let clt_deposited = CltDeposited {
//             token: type_name::into_string((type_name::get<T>())),
//             owner: sender,
//             nonce,
//             balance,
//             total_deposit,
//         };

//         event::emit(clt_deposited);

//         let minted_balance = coin::mint_balance(
//             treasureMut(vault),
//             balance
//         );

//         let peeled_vec_u128 = bcs::peel_vec_u128(&mut bcs_payload);
//         let peeled_u64 = bcs::peel_u64(&mut bcs_payload);

//         (minted_balance, deposit_proof, peeled_vec_u128, peeled_u64)
//     }

//     public fun depositTokenForNftIds<T>(
//         signature: vector<u8>,
//         payload: vector<u8>,
//         vault: &mut CltVault<T>,
//         user_archieve: &mut archieve::UserArchieve,
//         version: &version::Version,
//         clock: &clock::Clock,
//         ctx: &mut tx_context::TxContext
//     ): (balance::Balance<T>, DepositProof, vector<address>, u64) {
//         version::checkVersion(version, 1);
//         archieve::verifySignature(signature, payload, &vault.validator);

//         let sender = tx_context::sender(ctx);
//         let bcs_payload = bcs::new(payload);
//         let balance = bcs::peel_u64(&mut bcs_payload);
//         let nonce = bcs::peel_u128(&mut bcs_payload);
//         let peeled_address = bcs::peel_address(&mut bcs_payload);
//         let expiration_time = bcs::peel_u64(&mut bcs_payload);

//         assert!(peeled_address == sender, 1001);
//         assert!(balance > 0, 1002);
//         assert!(expiration_time > clock::timestamp_ms(clock), 1004);

//         archieve::verUpdateTokenPegNonce(nonce, user_archieve);

//         let deposit_proof = DepositProof {
//             owner: sender,
//             balance,
//         };

//         let total_deposit = archieve::increaseTotalDeposit(balance, user_archieve);

//         let clt_deposited = CltDeposited {
//             token: type_name::into_string((type_name::get<T>())),
//             owner: sender,
//             nonce,
//             balance,
//             total_deposit,
//         };

//         event::emit(clt_deposited);

//         let treasure = treasureMut<T>(vault);
//         let minted_balance = coin::mint_balance(treasure, balance);
//         let addresses = bcs::peel_vec_address(&mut bcs_payload);
//         let peeled_u64 = bcs::peel_u64(&mut bcs_payload);

//         (minted_balance, deposit_proof, addresses, peeled_u64)
//     }

//     public fun verifyDepositProof<T>(
//         balance: &balance::Balance<T>,
//         deposit_proof: DepositProof
//     ) {
//         assert!(
//             balance::value(balance) == deposit_proof.balance,
//             1003
//         );
//         let DepositProof {
//             owner: _,
//             balance: _,
//         } = deposit_proof;
//     }

//     public(package) fun withdrawTo<T>(
//         balance: balance::Balance<T>,
//         owner: address,
//         vault: &mut CltVault<T>,
//         ctx: &mut tx_context::TxContext
//     ) {
//         coin::burn(
//             &mut vault.treasureCap,
//             coin::from_balance(balance, ctx)
//         );
//         vault.burn_nonce = vault.burn_nonce + 1;
//         let event = CltWithdrawn {
//             token: type_name::into_string((type_name::get<T>())),
//             owner,
//             nonce: vault.burn_nonce,
//             balance: balance::value(&balance),
//         };
//         event::emit(event);
//     }
// }