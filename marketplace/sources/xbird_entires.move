// // Decompiled by SuiGPT
// module 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::xbird_entries {

//     // ----- Use Statements -----

//     use 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::market;
//     use 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::payment_policy;
//     use sui::coin;
//     use sui::clock;
//     use 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::version;
//     use sui::tx_context;
//     use sui::object;
//     use sui::sui;
//     use 0x38dba0f0cf9a80c9b9debf580c82f89bb0de4577e6fb448b3ba2ee9e05d539bc::archieve;
//     use 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::clt;
//     use 0xf81f4425196a7520875bc0deaca6c206f7516b960214bc6e52569b948409eb08::xbird;
//     use sui::transfer;
//     use 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::obutils;
//     use 0x38dba0f0cf9a80c9b9debf580c82f89bb0de4577e6fb448b3ba2ee9e05d539bc::cap_vault;
//     use sui::package;
//     use 0x356d0c33487d727fa31198d1ac9e082a5b57a89c6b56dd37fdf9d54db9d9f98d::nft;
//     use 0x38dba0f0cf9a80c9b9debf580c82f89bb0de4577e6fb448b3ba2ee9e05d539bc::version as version_1;

//     // ----- Functions -----

//     public entry fun buyCross<T0: store + key, T1>(
//         market: &mut market::Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         payment: coin::Coin<T1>,
//         buyer_address: address,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         market::buy_cross<T0, T1>(
//             market,
//             policy_vault,
//             payment,
//             object::id_from_address(buyer_address),
//             clock,
//             version,
//             ctx
//         );
//     }

//     public entry fun buyCrossByOrderId<T0: store + key, T1>(
//         market: &mut market::Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         payment_coin: coin::Coin<T1>,
//         amount: u128,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         market::buy_cross_orderid<T0, T1>(
//             market,
//             policy_vault,
//             payment_coin,
//             amount,
//             clock,
//             version,
//             ctx
//         );
//     }

//     public entry fun buyCrossClt<T: store + key>(
//         clt_id: vector<u8>,
//         clt_data: vector<u8>,
//         payment: coin::Coin<sui::SUI>,
//         user_archieve: &mut archieve::UserArchieve,
//         market: &mut market::Market,
//         policy_vault: &mut payment_policy::PolicyVault<T>,
//         clt_vault: &mut clt::CltVault<xbird::XBIRD>,
//         buyer_address: address,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         let (clt_token, clt_metadata, clt_amount) = clt::depositToken<
//             xbird::XBIRD
//         >(clt_id, clt_data, clt_vault, user_archieve, version, clock, ctx);

//         market::buy_cross_clt<
//             T,
//             xbird::XBIRD
//         >(
//             market,
//             policy_vault,
//             &mut payment,
//             clt_amount,
//             clt_vault,
//             clt_token,
//             clt_metadata,
//             object::id_from_address(buyer_address),
//             clock,
//             version,
//             ctx
//         );

//         transfer::public_transfer(payment, tx_context::sender(ctx));
//     }

//     public entry fun buyCrossCltByOrderId<T: store + key>(
//         order_id: vector<u8>,
//         buyer_id: vector<u8>,
//         payment: coin::Coin<sui::SUI>,
//         user_archieve: &mut archieve::UserArchieve,
//         market: &mut market::Market,
//         policy_vault: &mut payment_policy::PolicyVault<T>,
//         clt_vault: &mut clt::CltVault<xbird::XBIRD>,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         let (deposit_result_1, deposit_result_2, deposit_result_3, deposit_result_4) = 
//             clt::depositTokenForOrder<
//                 xbird::XBIRD
//             >(
//                 order_id,
//                 buyer_id,
//                 clt_vault,
//                 user_archieve,
//                 version,
//                 clock,
//                 ctx
//             );

//         market::buy_cross_clt_orderid<
//             T,
//             xbird::XBIRD
//         >(
//             market,
//             policy_vault,
//             &mut payment,
//             deposit_result_4,
//             clt_vault,
//             deposit_result_1,
//             deposit_result_2,
//             deposit_result_3,
//             clock,
//             version,
//             ctx
//         );

//         transfer::public_transfer(payment, tx_context::sender(ctx));
//     }

//     public entry fun buyLimit<T0: store + key, T1>(
//         market: &mut market::Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         payment: coin::Coin<T1>,
//         price: u64,
//         quantity: u64,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         market::buy_limit<T0, T1>(
//             market,
//             policy_vault,
//             payment,
//             price,
//             quantity,
//             clock,
//             version,
//             ctx
//         );
//     }

//     public entry fun buyLimitClt<T: store + key>(
//         user_id: vector<u8>,
//         order_id: vector<u8>,
//         user_archieve: &mut archieve::UserArchieve,
//         market: &mut market::Market,
//         policy_vault: &mut payment_policy::PolicyVault<T>,
//         clt_vault: &mut clt::CltVault<xbird::XBIRD>,
//         amount: u64,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         let (deposited_amount, deposited_clt, _) = clt::depositToken<
//             xbird::XBIRD
//         >(user_id, order_id, clt_vault, user_archieve, version, clock, ctx);

//         market::buy_limit_clt<
//             T, xbird::XBIRD
//         >(
//             market,
//             policy_vault,
//             clt_vault,
//             deposited_amount,
//             deposited_clt,
//             amount,
//             0,
//             clock,
//             version,
//             ctx
//         );
//     }

//     public entry fun buyMarket<T0: store + key, T1>(
//         market: &mut market::Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         payment: coin::Coin<T1>,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         market::buy_flash<T0, T1>(
//             market,
//             policy_vault,
//             payment,
//             clock,
//             version,
//             ctx
//         );
//     }

//     public entry fun buyMarketClt<T: store + key>(
//         token_id: vector<u8>,
//         user_id: vector<u8>,
//         user_archieve: &mut archieve::UserArchieve,
//         market: &mut market::Market,
//         policy_vault: &mut payment_policy::PolicyVault<T>,
//         clt_vault: &mut clt::CltVault<xbird::XBIRD>,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         let (deposit_token, deposit_amount, _) = clt::depositToken<
//             xbird::XBIRD
//         >(token_id, user_id, clt_vault, user_archieve, version, clock, ctx);

//         market::buy_flash_clt<
//             T, xbird::XBIRD
//         >(market, policy_vault, clt_vault, deposit_token, deposit_amount, clock, version, ctx);
//     }

//     public entry fun cancelBuy<T0: store + key, T1>(
//         market: &mut market::Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         amounts: vector<u128>,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         market::cancel_buy<T0, T1>(
//             market,
//             policy_vault,
//             amounts,
//             version,
//             ctx
//         );
//     }

//     public entry fun cancelBuyClt<T0: store + key, T1>(
//         market: &mut market::Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         clt_vault: &mut clt::CltVault<T1>,
//         amounts: vector<u128>,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         market::cancel_buy_clt<T0, T1>(
//             market,
//             policy_vault,
//             clt_vault,
//             amounts,
//             version,
//             ctx
//         );
//     }

//     public entry fun cancelSell<T0: store + key, T1>(
//         market: &mut market::Market,
//         addresses: vector<address>,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         market::cancel_sell<T0, T1>(
//             market,
//             obutils::vec_toids(&addresses),
//             version,
//             ctx
//         );
//     }

//     public entry fun cancelSellByOrderId<T0: store + key, T1>(
//         market: &mut market::Market,
//         order_ids: vector<u128>,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         market::cancel_sell_ordid<T0, T1>(
//             market,
//             order_ids,
//             version,
//             ctx
//         );
//     }

//     public entry fun claimCap<T: store + key>(
//         cap_vault: &mut cap_vault::CapVault<T>,
//         ctx: &tx_context::TxContext
//     ) {
//         let claimed_cap = cap_vault::claim_cap(cap_vault, ctx);
//         let sender = tx_context::sender(ctx);
//         transfer::public_transfer(claimed_cap, sender);
//     }

//     public entry fun createClt<T>(
//         treasury_cap: coin::TreasuryCap<T>,
//         coin_metadata: coin::CoinMetadata<T>,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         let clt_admin_cap = clt::createClt(
//             treasury_cap,
//             coin_metadata,
//             version,
//             ctx
//         );
//         transfer::public_transfer(clt_admin_cap, tx_context::sender(ctx));
//     }

//     public entry fun createMarket<T0: store + key, T1>(
//         admin_cap: &market::MarketAdminCap,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         is_active: bool,
//         fee_rate: u64,
//         min_order_size: u64,
//         max_order_size: u64,
//         tick_size: u64,
//         lot_size: u64,
//         allow_partial_fill: bool,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         market::createMarket<T0, T1>(
//             admin_cap,
//             policy_vault,
//             is_active,
//             fee_rate,
//             min_order_size,
//             max_order_size,
//             tick_size,
//             lot_size,
//             allow_partial_fill,
//             version,
//             ctx
//         );
//     }

//     public entry fun createPolicy<T0: store + key, T1>(
//         publisher: &package::Publisher,
//         param1: u64,
//         param2: u64,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         let policy_vault_cap = payment_policy::createPolicy<T0, T1>(
//             publisher,
//             param1,
//             param2,
//             version,
//             ctx
//         );
//         transfer::public_transfer(policy_vault_cap, tx_context::sender(ctx));
//     }

//     public entry fun depositNft(
//         nft_id: vector<u8>,
//         user_id: vector<u8>,
//         nft_peg_vault: &mut nft::NftPegVault,
//         user_archieve: &mut archieve::UserArchieve,
//         payment: coin::Coin<sui::SUI>,
//         version: &version_1::Version,
//         clock: &clock::Clock,
//         ctx: &mut tx_context::TxContext
//     ) {
//         nft::depositNft(
//             nft_id,
//             user_id,
//             nft_peg_vault,
//             user_archieve,
//             payment,
//             version,
//             clock,
//             ctx
//         );
//     }

//     public entry fun migrateVersion(
//         admin_cap: &version::VerAdminCap,
//         version: &mut version::Version,
//         new_version: u64
//     ) {
//         version::migrate(admin_cap, version, new_version);
//     }

//     public entry fun register(
//         user_reg: &mut archieve::UserReg,
//         ctx: &mut tx_context::TxContext
//     ) {
//         let user_archieve = archieve::register(user_reg, ctx);
//         transfer::public_transfer(user_archieve, tx_context::sender(ctx));
//     }

//     public entry fun revokeCap<T: store + key>(
//         cap_vault: &mut cap_vault::CapVault<T>,
//         ctx: &mut tx_context::TxContext
//     ) {
//         let revoked_cap = cap_vault::revoke_cap<T>(cap_vault, ctx);
//         transfer::public_transfer(revoked_cap, tx_context::sender(ctx));
//     }

//     public entry fun sellFlash<T0: store + key, T1>(
//         market: &mut market::Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         asset: T0,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         market::sell_flash<T0, T1>(
//             market,
//             policy_vault,
//             asset,
//             clock,
//             version,
//             ctx
//         );
//     }

//     public entry fun sellFlashClt<T0: store + key, T1>(
//         market: &mut market::Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         clt_vault: &mut clt::CltVault<T1>,
//         payment: T0,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         market::sell_flash_clt<T0, T1>(
//             market,
//             policy_vault,
//             clt_vault,
//             payment,
//             clock,
//             version,
//             ctx
//         );
//     }

//     public entry fun sellLimit<T0: store + key, T1>(
//         market: &mut market::Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         item: T0,
//         quantity: u64,
//         clock: &clock::Clock,
//         price: u64,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         market::sell_limit<T0, T1>(
//             market,
//             policy_vault,
//             item,
//             quantity,
//             price,
//             clock,
//             version,
//             ctx
//         );
//     }

//     public entry fun sellLimitClt<T0: store + key, T1>(
//         market: &mut market::Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         clt_vault: &mut clt::CltVault<T1>,
//         payment: T0,
//         amount: u64,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         market::sell_limit_clt<T0, T1>(
//             market,
//             policy_vault,
//             clt_vault,
//             payment,
//             amount,
//             0,
//             clock,
//             version,
//             ctx
//         );
//     }

//     public entry fun setValidator<T>(
//         admin_cap: &clt::CltAdminCap,
//         validator_key: vector<u8>,
//         vault: &mut clt::CltVault<T>,
//         version: &version::Version
//     ) {
//         clt::setValidator<T>(
//             admin_cap,
//             validator_key,
//             vault,
//             version
//         );
//     }

//     public entry fun setValidatorNft(
//         admin_cap: &nft::NftAdminCap,
//         validator_key: vector<u8>,
//         peg_vault: &mut nft::NftPegVault,
//         version: &version_1::Version
//     ) {
//         nft::setValidator(
//             admin_cap,
//             validator_key,
//             peg_vault,
//             version
//         );
//     }

//     public entry fun sweep<T0: store + key, T1>(
//         market: &mut market::Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         addresses: vector<address>,
//         coin: &mut coin::Coin<T1>,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         market::sweep<T0, T1>(
//             market,
//             policy_vault,
//             obutils::vec_toids(&addresses),
//             coin,
//             clock,
//             version,
//             ctx
//         );
//     }

//     public entry fun sweepCltByNftId<T: store + key>(
//         nft_ids: vector<u8>,
//         nft_data: vector<u8>,
//         sui_coin: coin::Coin<sui::SUI>,
//         user_archieve: &mut archieve::UserArchieve,
//         market: &mut market::Market,
//         policy_vault: &mut payment_policy::PolicyVault<T>,
//         clt_vault: &mut clt::CltVault<xbird::XBIRD>,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         let (deposited_ids, deposited_data, deposited_clt, nft_ids_vec) = clt::depositTokenForNftIds<
//             xbird::XBIRD
//         >(nft_ids, nft_data, clt_vault, user_archieve, version, clock, ctx);

//         let clt_ids = nft_ids_vec;

//         market::sweep_clt<
//             T,
//             xbird::XBIRD
//         >(
//             market,
//             policy_vault,
//             &mut sui_coin,
//             nft_ids_vec,
//             clt_vault,
//             obutils::vec_toids(&clt_ids),
//             deposited_ids,
//             deposited_data,
//             clock,
//             version,
//             ctx
//         );

//         transfer::public_transfer(sui_coin, tx_context::sender(ctx));
//     }

//     public entry fun sweepCltByOrderId<T: store + key>(
//         order_id: vector<u8>,
//         user_id: vector<u8>,
//         sui_coin: coin::Coin<sui::SUI>,
//         user_archieve: &mut archieve::UserArchieve,
//         market: &mut market::Market,
//         policy_vault: &mut payment_policy::PolicyVault<T>,
//         clt_vault: &mut clt::CltVault<xbird::XBIRD>,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         let (deposited_amount, remaining_amount, order_ids, clt_amount) = clt::depositTokenForOrderIds<xbird::XBIRD>(
//             order_id,
//             user_id,
//             clt_vault,
//             user_archieve,
//             version,
//             clock,
//             ctx
//         );
//         market::sweep_clt_orderids<T, xbird::XBIRD>(
//             market,
//             policy_vault,
//             &mut sui_coin,
//             clt_amount,
//             clt_vault,
//             remaining_amount,
//             deposited_amount,
//             order_ids,
//             clock,
//             version,
//             ctx
//         );
//         transfer::public_transfer(sui_coin, tx_context::sender(ctx));
//     }

//     public entry fun transferCap<T: store + key>(
//         cap: T,
//         recipient: address,
//         cap_vault: &mut cap_vault::CapVault<T>,
//         ctx: &mut tx_context::TxContext
//     ) {
//         cap_vault::transfer_cap(cap, recipient, cap_vault, ctx);
//     }

//     public entry fun withdrawMarketFee<T0: store + key, T1>(
//         market_treasure_cap: &market::MarketTreasureCap,
//         market: &mut market::Market,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         let fee_balance = market::withdraw_fee<T0, T1>(
//             market_treasure_cap,
//             market,
//             version
//         );
//         let fee_coin = coin::from_balance(fee_balance, ctx);
//         transfer::public_transfer(fee_coin, tx_context::sender(ctx));
//     }

//     public entry fun withdrawMarketFeeClt<T0: store + key, T1>(
//         market_treasure_cap: &market::MarketTreasureCap,
//         clt_vault: &mut clt::CltVault<T1>,
//         recipient: address,
//         market: &mut market::Market,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         market::withdraw_fee_clt<T0, T1>(
//             market_treasure_cap,
//             clt_vault,
//             recipient,
//             market,
//             version,
//             ctx
//         );
//     }

//     public entry fun withdrawNft(
//         user_archieve: &mut archieve::UserArchieve,
//         bird_nft: nft::BirdNFT,
//         version: &version_1::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         nft::withdrawNft(
//             user_archieve,
//             bird_nft,
//             version,
//             ctx
//         );
//     }

//     public entry fun withdrawNftMintFee(
//         admin_cap: &nft::NftAdminCap,
//         peg_vault: &mut nft::NftPegVault,
//         version: &version_1::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         let fee = nft::withdrawFee(admin_cap, peg_vault, version, ctx);
//         transfer::public_transfer<coin::Coin<sui::SUI>>(fee, tx_context::sender(ctx));
//     }

//     public entry fun withdrawRoyalFeeCoin<T0: store + key, T1>(
//         policy_vault_cap: &payment_policy::PolicyVaultCap,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         ctx: &mut tx_context::TxContext
//     ) {
//         let royal_fee_coin = payment_policy::withdrawRoyalFeeCoin<T0, T1>(
//             policy_vault_cap,
//             policy_vault,
//             ctx
//         );
//         transfer::public_transfer(royal_fee_coin, tx_context::sender(ctx));
//     }

//     public entry fun withdrawRoyalFeeToken<T0: store + key, T1>(
//         policy_vault_cap: &payment_policy::PolicyVaultCap,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         clt_vault: &mut clt::CltVault<T1>,
//         ctx: &mut tx_context::TxContext
//     ) {
//         payment_policy::withdrawRoyalFeeToken<T0, T1>(
//             policy_vault_cap,
//             policy_vault,
//             clt_vault,
//             ctx
//         );
//     }
// }