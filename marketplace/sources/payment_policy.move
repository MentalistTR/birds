// // Decompiled by SuiGPT
// module 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::payment_policy {

//     // ----- Use Statements -----

//     use sui::object;
//     use sui::transfer_policy;
//     use sui::balance;
//     use sui::dynamic_field;
//     use std::type_name;
//     use sui::tx_context;
//     use sui::package;
//     use 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::version;
//     use sui::transfer;
//     use 0x38dba0f0cf9a80c9b9debf580c82f89bb0de4577e6fb448b3ba2ee9e05d539bc::cap_vault;
//     use sui::coin;
//     use 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::clt;
//     use 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::public_kiosk;
//     use 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::constants;
//     use 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::math;

//     // ----- Structs -----

//     struct PAYMENT_POLICY has drop {
//         dummy_field: bool,
//     }

//     struct PolicyVault<phantom T0> has store, key {
//         id: object::UID,
//         policy: transfer_policy::TransferPolicy<T0>,
//         policyCap: transfer_policy::TransferPolicyCap<T0>,
//     }

//     struct PolicyVaultCap has store, key {
//         id: object::UID,
//         policy_id: object::ID,
//     }

//     struct RoyalRule has drop {
//         dummy_field: bool,
//     }

//     struct TradeRule has drop {
//         dummy_field: bool,
//     }

//     // ----- Functions -----

//     fun addRoyalFee<T0, T1>(
//         policy_vault: &mut PolicyVault<T0>,
//         balance: balance::Balance<T1>
//     ) {
//         let policy_owner = transfer_policy::uid_mut_as_owner<T0>(
//             &mut policy_vault.policy,
//             &policy_vault.policyCap
//         );
//         let balance_type_name = type_name::get<balance::Balance<T1>>();
//         let mut_balance = dynamic_field::borrow_mut<type_name::TypeName, balance::Balance<T1>>(
//             policy_owner,
//             balance_type_name
//         );
//         balance::join<T1>(mut_balance, balance);
//     }

//     fun addRules<T: store + key>(
//         cap: &transfer_policy::TransferPolicyCap<T>,
//         policy: &mut transfer_policy::TransferPolicy<T>,
//         royal_limit: u64,
//         trade_limit: u64
//     ) {
//         assert!(royal_limit <= 1000 && trade_limit <= 2000, 4003);

//         let trade_rule = TradeRule { dummy_field: false };
//         transfer_policy::add_rule<T, TradeRule, u64>(trade_rule, policy, cap, trade_limit);

//         let royal_rule = RoyalRule { dummy_field: false };
//         transfer_policy::add_rule<T, RoyalRule, u64>(royal_rule, policy, cap, royal_limit);
//     }

//     fun init(
//         payment_policy: PAYMENT_POLICY,
//         ctx: &mut tx_context::TxContext
//     ) {
//     }

//     fun withdrawRoyalFee<T0: store + key, T1>(
//         policy_vault_cap: &PolicyVaultCap,
//         policy_vault: &mut PolicyVault<T0>
//     ): balance::Balance<T1> {
//         assert!(
//             policy_vault_cap.policy_id == object::id<PolicyVault<T0>>(policy_vault),
//             4004
//         );

//         let policy_owner = transfer_policy::uid_mut_as_owner<T0>(
//             &mut policy_vault.policy,
//             &policy_vault.policyCap
//         );
//         let type_name = type_name::get<balance::Balance<T1>>();
//         let balance = dynamic_field::borrow_mut<type_name::TypeName, balance::Balance<T1>>(
//             policy_owner,
//             type_name
//         );
//         let balance_value = balance::value<T1>(balance);
//         balance::split<T1>(balance, balance_value)
//     }

//     public fun createPolicy<T0: store + key, T1>(
//         publisher: &package::Publisher,
//         rule1: u64,
//         rule2: u64,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ): PolicyVaultCap {
//         version::checkVersion(version, 1);

//         let (policy_cap, policy) = transfer_policy::new<T0>(publisher, ctx);
//         let policy_cap_ref = policy_cap;
//         let policy_ref = policy;

//         dynamic_field::add<type_name::TypeName, balance::Balance<T1>>(
//             transfer_policy::uid_mut_as_owner<T0>(&mut policy_ref, &policy_cap_ref),
//             type_name::get<balance::Balance<T1>>(),
//             balance::zero<T1>()
//         );

//         addRules<T0>(&policy_cap_ref, &mut policy_ref, rule1, rule2);

//         let policy_vault = PolicyVault<T0> {
//             id: object::new(ctx),
//             policy: policy_ref,
//             policyCap: policy_cap_ref,
//         };

//         transfer::public_share_object(policy_vault);

//         let policy_vault_cap = PolicyVaultCap {
//             id: object::new(ctx),
//             policy_id: object::id(&policy_vault),
//         };

//         cap_vault::createVault<PolicyVaultCap>(ctx);

//         policy_vault_cap
//     }

//     public(package) fun payByClt<T0: store + key, T1>(
//         clt_vault: &mut clt::CltVault<T1>,
//         policy_vault: &mut PolicyVault<T0>,
//         transfer_request: transfer_policy::TransferRequest<T0>,
//         order: &public_kiosk::KOrder,
//         balance: &mut balance::Balance<T1>,
//         trade_fee: u64,
//         ctx: &mut tx_context::TxContext
//     ): (balance::Balance<T1>, u64, u64) {
//         let (_, item_id, recipient, order_amount) = public_kiosk::orderInfo(order);
//         assert!(item_id == transfer_policy::item(&transfer_request), 4002);
//         assert!(order_amount == 0 || order_amount <= balance::value(balance), 4001);

//         let trade_rule = TradeRule { dummy_field: false };
//         let royal_rule = RoyalRule { dummy_field: false };

//         assert!(
//             trade_fee <= *transfer_policy::get_rule<T0, TradeRule, u64>(trade_rule, &policy_vault.policy),
//             4003
//         );

//         let effective_amount = if (order_amount == 0) {
//             balance::value(balance)
//         } else {
//             order_amount
//         };

//         let max_fee = constants::max_fee();
//         let trade_fee_amount = math::div(
//             math::mul(effective_amount, trade_fee),
//             max_fee
//         );
//         let royal_fee_amount = math::div(
//             math::mul(
//                 effective_amount,
//                 *transfer_policy::get_rule<T0, RoyalRule, u64>(royal_rule, &policy_vault.policy)
//             ),
//             max_fee
//         );

//         clt::withdrawTo(
//             balance::split(balance, effective_amount - trade_fee_amount - royal_fee_amount),
//             recipient,
//             clt_vault,
//             ctx
//         );

//         addRoyalFee(
//             policy_vault,
//             balance::split(balance, royal_fee_amount)
//         );

//         let trade_rule_receipt = TradeRule { dummy_field: false };
//         transfer_policy::add_receipt(trade_rule_receipt, &mut transfer_request);

//         let royal_rule_receipt = RoyalRule { dummy_field: false };
//         transfer_policy::add_receipt(royal_rule_receipt, &mut transfer_request);

//         let (_, _, _) = transfer_policy::confirm_request(&policy_vault.policy, transfer_request);

//         (balance::split(balance, trade_fee_amount), trade_fee_amount, royal_fee_amount)
//     }

//     public(package) fun payByCoin<T0: store + key, T1>(
//         policy_vault: &mut PolicyVault<T0>,
//         transfer_request: transfer_policy::TransferRequest<T0>,
//         order: &public_kiosk::KOrder,
//         balance: &mut balance::Balance<T1>,
//         trade_fee: u64,
//         ctx: &mut tx_context::TxContext
//     ): (balance::Balance<T1>, u64, u64) {
//         let (_, item, recipient, price) = public_kiosk::orderInfo(order);
//         assert!(item == transfer_policy::item(&transfer_request), 4002);
//         assert!(price == 0 || price <= balance::value(balance), 4001);

//         let trade_rule = TradeRule { dummy_field: false };
//         let royal_rule = RoyalRule { dummy_field: false };

//         assert!(
//             trade_fee <= *transfer_policy::get_rule<T0, TradeRule, u64>(trade_rule, &policy_vault.policy),
//             4003
//         );

//         let effective_price = if (price == 0) {
//             balance::value(balance)
//         } else {
//             price
//         };

//         let max_fee = constants::max_fee();
//         let trade_fee_amount = math::div(
//             math::mul(effective_price, trade_fee),
//             max_fee
//         );
//         let royal_fee_amount = math::div(
//             math::mul(
//                 effective_price,
//                 *transfer_policy::get_rule<T0, RoyalRule, u64>(royal_rule, &policy_vault.policy)
//             ),
//             max_fee
//         );

//         transfer::public_transfer(
//             coin::from_balance(
//                 balance::split(balance, effective_price - trade_fee_amount - royal_fee_amount),
//                 ctx
//             ),
//             recipient
//         );

//         addRoyalFee(policy_vault, balance::split(balance, royal_fee_amount));

//         let trade_rule_receipt = TradeRule { dummy_field: false };
//         transfer_policy::add_receipt(trade_rule_receipt, &mut transfer_request);

//         let royal_rule_receipt = RoyalRule { dummy_field: false };
//         transfer_policy::add_receipt(royal_rule_receipt, &mut transfer_request);

//         let (_, _, _) = transfer_policy::confirm_request(&policy_vault.policy, transfer_request);

//         (balance::split(balance, trade_fee_amount), trade_fee_amount, royal_fee_amount)
//     }

//     public fun withdrawRoyalFeeCoin<T0: store + key, T1>(
//         policy_vault_cap: &PolicyVaultCap,
//         policy_vault: &mut PolicyVault<T0>,
//         ctx: &mut tx_context::TxContext
//     ): coin::Coin<T1> {
//         let royal_fee_balance = withdrawRoyalFee<T0, T1>(policy_vault_cap, policy_vault);
//         coin::from_balance(royal_fee_balance, ctx)
//     }

//     public fun withdrawRoyalFeeToken<T0: store + key, T1>(
//         policy_vault_cap: &PolicyVaultCap,
//         policy_vault: &mut PolicyVault<T0>,
//         clt_vault: &mut clt::CltVault<T1>,
//         ctx: &mut tx_context::TxContext
//     ) {
//         let royal_fee = withdrawRoyalFee<T0, T1>(policy_vault_cap, policy_vault);
//         let sender = tx_context::sender(ctx);
//         clt::withdrawTo(royal_fee, sender, clt_vault, ctx);
//     }
// }