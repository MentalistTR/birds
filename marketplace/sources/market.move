// // Decompiled by SuiGPT
// module 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::market {

//     // ----- Use Statements -----

//     use sui::balance;
//     use sui::object;
//     use std::ascii;
//     use std::type_name;
//     use sui::dynamic_field;
//     use 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::payment_policy;
//     use sui::coin;
//     use sui::sui;
//     use 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::clt;
//     use sui::clock;
//     use 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::version;
//     use sui::tx_context;
//     use 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::public_kiosk;
//     use 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::book;
//     use std::option;
//     use 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::constants;
//     use std::vector;
//     use sui::transfer;
//     use sui::transfer_policy;
//     use sui::event;
//     use std::u64;
//     use 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::math;
//     use 0x38dba0f0cf9a80c9b9debf580c82f89bb0de4577e6fb448b3ba2ee9e05d539bc::cap_vault;

//     // ----- Structs -----

//     struct Analysis has store {
//         floor: u64,
//         ceil: u64,
//         vol: u128,
//         bids_size: u64,
//         asks_size: u64,
//     }

//     struct BalanceManager<phantom T0> has store {
//         balance: balance::Balance<T0>,
//         fee: balance::Balance<T0>,
//     }

//     struct Config has store {
//         tick_size: u64,
//         min_size: u64,
//         base_fee: u64,
//         allow_self_match: bool,
//         max_order: u64,
//         min_offer_per: u64,
//     }

//     struct MARKET has drop {
//         dummy_field: bool,
//     }

//     struct Market has store, key {
//         id: object::UID,
//         policy: object::ID,
//         pair: Pair,
//         coin_or_clt: bool,
//     }

//     struct MarketAdminCap has store, key {
//         id: object::UID,
//     }

//     struct MarketAnalysis has copy, drop, store {
//         id: object::ID,
//         vol: u128,
//         floor: u64,
//         ceil: u64,
//         bids_size: u64,
//         asks_size: u64,
//         timestamp: u64,
//     }

//     struct MarketCreated has copy, drop, store {
//         id: object::ID,
//         bid: ascii::String,
//         ask: ascii::String,
//         coin_or_clt: bool,
//         tick_size: u64,
//         min_size: u64,
//         base_fee: u64,
//         max_order: u64,
//         allow_self_match: bool,
//         policy: address,
//     }

//     struct MarketTreasureCap has store, key {
//         id: object::UID,
//     }

//     struct Pair has copy, drop, store {
//         nft: type_name::TypeName,
//         token: type_name::TypeName,
//     }

//     // ----- Functions -----

//     fun analysis(market: &Market): &Analysis {
//         dynamic_field::borrow<type_name::TypeName, Analysis>(
//             &market.id,
//             type_name::get<Analysis>()
//         )
//     }

//     fun analysis_mut(
//         market: &mut Market
//     ): &mut Analysis {
//         dynamic_field::borrow_mut<type_name::TypeName, Analysis>(
//             &mut market.id,
//             type_name::get<Analysis>()
//         )
//     }

//     fun balance_vault<T>(
//         market: &mut Market
//     ): &mut BalanceManager<T> {
//         dynamic_field::borrow_mut<type_name::TypeName, BalanceManager<T>>(
//             &mut market.id,
//             type_name::get<BalanceManager<T>>()
//         )
//     }

//     fun buy_cross_clt_int<T0: store + key, T1>(
//         market: &mut Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         sui_coin: &mut coin::Coin<sui::SUI>,
//         rebate_fee: u64,
//         clt_vault: &mut clt::CltVault<T1>,
//         balance: balance::Balance<T1>,
//         order_id: object::ID,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         version::checkVersion(version, 1);
//         validateMarket<T0, T1>(true, market, policy_vault, false);

//         let balance_value = balance::value(&balance);
//         let order_price = public_kiosk::orderPrice(pkiosk_mut(market), order_id);
//         assert!(balance_value >= order_price, 6005);

//         let order_internal_id = public_kiosk::orderIdFromNft(pkiosk_mut(market), order_id);
//         let current_timestamp = clock::timestamp_ms(clock);
//         assert!(
//             !book::order_expired(orderbook_mut(market), order_internal_id, current_timestamp),
//             6006
//         );

//         deposit_balance<T1>(market, balance);

//         let order_info = book::make_order_info(
//             object::id(market),
//             tx_context::sender(ctx),
//             balance_value,
//             true,
//             option::some(order_id),
//             0,
//             constants::ord_cross(),
//             order_internal_id,
//             0,
//             constants::ice_berge()
//         );

//         let (matched_qty, matched_price, matched_fee, matched_rebate) = book::place_cross(
//             orderbook_mut(market),
//             &order_info,
//             config(market).allow_self_match,
//             current_timestamp
//         );

//         deliver_cross_clt<T0, T1>(
//             clt_vault,
//             policy_vault,
//             matched_qty,
//             matched_price,
//             matched_fee,
//             matched_rebate,
//             market,
//             version,
//             current_timestamp,
//             ctx
//         );

//         update_analysis_bsize(market, current_timestamp);
//         deliverRebateFee0(sui_coin, rebate_fee, &matched_qty, ctx);
//     }

//     fun config(market: &Market): &Config {
//         dynamic_field::borrow<type_name::TypeName, Config>(
//             &market.id,
//             type_name::get<Config>()
//         )
//     }

//     fun config_mut(market: &mut Market): &mut Config {
//         dynamic_field::borrow_mut<type_name::TypeName, Config>(
//             &mut market.id,
//             type_name::get<Config>()
//         )
//     }

//     fun deliver<T0: store + key, T1>(
//         trade_proof: book::TradeProof,
//         market: &mut Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         version: &version::Version,
//         analysis_exec: u64,
//         ctx: &mut tx_context::TxContext
//     ) {
//         let (bills, expired_bills) = book::bill_info(&trade_proof);
//         let bills_length = vector::length<book::Bill>(bills);

//         while (bills_length > 0) {
//             let index = bills_length - 1;
//             bills_length = index;
//             let bill = vector::borrow<book::Bill>(bills, index);
//             let (is_sender, recipient, amount, exec, nft_id) = book::fill_info(bill);
//             let recipient_address = if (is_sender) {
//                 tx_context::sender(ctx)
//             } else {
//                 recipient
//             };
//             let split_balance = balance::split<T1>(&mut balance_vault<T1>(market).balance, amount);
//             let (_, delivered_amount, delivered_exec) = deliverNft<T0, T1>(market, policy_vault, nft_id, &mut split_balance, recipient_address, version, ctx);
//             book::make_and_fire_event_filled(
//                 object::id<Market>(market),
//                 bill,
//                 delivered_amount,
//                 delivered_exec
//             );
//             deposit_balance<T1>(market, split_balance);
//             update_analysis_exec(market, amount, exec, analysis_exec);
//         };

//         let expired_bills_length = vector::length<book::ExpiredBill>(expired_bills);

//         while (expired_bills_length > 0) {
//             let index = expired_bills_length - 1;
//             expired_bills_length = index;
//             let (is_sender, recipient, amount, nft_id) = book::expired_info(
//                 vector::borrow<book::ExpiredBill>(expired_bills, index)
//             );
//             if (is_sender) {
//                 transfer::public_transfer<coin::Coin<T1>>(
//                     coin::from_balance<T1>(
//                         balance::split<T1>(&mut balance_vault<T1>(market).balance, amount),
//                         ctx
//                     ),
//                     recipient
//                 );
//                 continue;
//             };
//             public_kiosk::delistAndTake<T0, T1>(
//                 pkiosk_mut(market),
//                 *option::borrow<object::ID>(&nft_id),
//                 version,
//                 ctx
//             );
//         };

//         let (refund_address, _, is_refundable, refund_amount, is_delistable, nft_id) = book::trade_info(&trade_proof);

//         if (!is_refundable) {
//             if (is_delistable) {
//                 if (refund_amount > 0) {
//                     refund_coin<T1>(balance_vault<T1>(market), refund_amount, refund_address, ctx);
//                 };
//             } else {
//                 if (refund_amount > 0) {
//                     public_kiosk::delistAndTake<T0, T1>(
//                         pkiosk_mut(market),
//                         *option::borrow<object::ID>(&nft_id),
//                         version,
//                         ctx
//                     );
//                 };
//             };
//         };

//         book::confirm_proof(trade_proof);
//     }

//     fun deliverNft<T0: store + key, T1>(
//         market: &mut Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         nft_id: object::ID,
//         balance: &mut balance::Balance<T1>,
//         recipient: address,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ): (u128, u64, u64) {
//         let (nft, transfer_policy, payment) = public_kiosk::purchase<T0, T1>(
//             pkiosk_mut(market),
//             nft_id,
//             version,
//             ctx
//         );

//         assert!(
//             object::id(&nft) == transfer_policy::item(&transfer_policy),
//             6002
//         );

//         let (fee, base_fee, total_fee) = payment_policy::payByCoin<T0, T1>(
//             policy_vault,
//             transfer_policy,
//             &payment,
//             balance,
//             config_mut(market).base_fee,
//             ctx
//         );

//         transfer::public_transfer(nft, recipient);
//         balance::join(&mut balance_vault<T1>(market).fee, fee);

//         (
//             public_kiosk::orderId(&payment),
//             base_fee,
//             total_fee
//         )
//     }

//     fun deliverNftClt<T0: store + key, T1>(
//         market: &mut Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         clt_vault: &mut clt::CltVault<T1>,
//         item_id: object::ID,
//         balance: &mut balance::Balance<T1>,
//         recipient: address,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ): (u128, u64, u64) {
//         let (item, transfer_policy, order) = public_kiosk::purchase<T0, T1>(
//             pkiosk_mut(market),
//             item_id,
//             version,
//             ctx
//         );

//         assert!(
//             object::id(&item) == transfer_policy::item(&transfer_policy),
//             6002
//         );

//         let (fee, clt_used, clt_remaining) = payment_policy::payByClt<T0, T1>(
//             clt_vault,
//             policy_vault,
//             transfer_policy,
//             &order,
//             balance,
//             config_mut(market).base_fee,
//             ctx
//         );

//         transfer::public_transfer(item, recipient);
//         balance::join(&mut balance_vault<T1>(market).fee, fee);

//         (
//             public_kiosk::orderId(&order),
//             clt_used,
//             clt_remaining
//         )
//     }

//     fun deliverRebateFee(
//         coin: &mut coin::Coin<sui::SUI>,
//         amount: u64,
//         bill_option: &option::Option<book::Bill>,
//         ctx: &mut tx_context::TxContext
//     ) {
//         assert!(coin::value(coin) >= amount, 6012);
//         if (option::is_some(bill_option)) {
//             let bill = option::borrow(bill_option);
//             let maker_address = book::fill_maker(bill);
//             let rebate_coin = coin::split(coin, amount, ctx);
//             transfer::public_transfer(rebate_coin, maker_address);
//         };
//     }

//     fun deliverRebateFee0(
//         coin: &mut coin::Coin<sui::SUI>,
//         amount: u64,
//         bill_option: &option::Option<book::Bill>,
//         ctx: &mut tx_context::TxContext
//     ) {
//         assert!(coin::value(coin) >= amount, 6012);
//         let recipient = if (option::is_some(bill_option)) {
//             book::fill_maker(
//                 option::borrow(bill_option)
//             )
//         } else {
//             tx_context::sender(ctx)
//         };
//         transfer::public_transfer(
//             coin::split(coin, amount, ctx),
//             recipient
//         );
//     }

//     fun deliver_clt<T0: store + key, T1>(
//         trade_proof: book::TradeProof,
//         market: &mut Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         clt_vault: &mut clt::CltVault<T1>,
//         version: &version::Version,
//         analysis_exec: u64,
//         ctx: &mut tx_context::TxContext
//     ) {
//         let (bills, expired_bills) = book::bill_info(&trade_proof);
//         let bill_count = vector::length(bills);

//         while (bill_count > 0) {
//             let bill = vector::borrow(bills, bill_count - 1);
//             let (is_sender, recipient, amount, exec, nft_id) = book::fill_info(bill);
//             let recipient_address = if (is_sender) {
//                 tx_context::sender(ctx)
//             } else {
//                 recipient
//             };
//             let split_balance = balance::split(&mut balance_vault<T1>(market).balance, amount);
//             let (_, event_filled, event_id) = deliverNftClt(market, policy_vault, clt_vault, nft_id, &mut split_balance, recipient_address, version, ctx);
//             book::make_and_fire_event_filled(object::id(market), bill, event_filled, event_id);
//             deposit_balance(market, split_balance);
//             update_analysis_exec(market, amount, exec, analysis_exec);
//             bill_count = bill_count - 1;
//         };

//         let expired_bill_count = vector::length(expired_bills);

//         while (expired_bill_count > 0) {
//             let expired_index = expired_bill_count - 1;
//             expired_bill_count = expired_index;
//             let (is_sender, recipient, amount, nft_id) = book::expired_info(vector::borrow(expired_bills, expired_index));
//             if (is_sender) {
//                 refund_balance(clt_vault, market, amount, recipient, ctx);
//                 continue;
//             };
//             public_kiosk::delistAndTake(pkiosk_mut(market), *option::borrow(&nft_id), version, ctx);
//         };

//         let (recipient, _, is_successful, amount, is_sender, nft_id) = book::trade_info(&trade_proof);

//         if (!is_successful) {
//             if (is_sender) {
//                 if (amount > 0) {
//                     refund_balance(clt_vault, market, amount, recipient, ctx);
//                 };
//             } else {
//                 if (amount > 0) {
//                     public_kiosk::delistAndTake(pkiosk_mut(market), *option::borrow(&nft_id), version, ctx);
//                 };
//             };
//         };

//         book::confirm_proof(trade_proof);
//     }

//     fun deliver_cross<T0: store + key, T1>(
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         bill_option: option::Option<book::Bill>,
//         expired_bill_option: option::Option<book::ExpiredBill>,
//         refund_address: address,
//         refund_amount: u64,
//         market: &mut Market,
//         version: &version::Version,
//         analysis_exec_param: u64,
//         ctx: &mut tx_context::TxContext
//     ) {
//         if (option::is_some(&bill_option)) {
//             let bill = option::extract(&mut bill_option);
//             let (is_direct, recipient, amount, exec_param, nft_id) = book::fill_info(&bill);
//             let final_recipient = if (is_direct) {
//                 tx_context::sender(ctx)
//             } else {
//                 recipient
//             };
//             let split_balance = balance::split(&mut balance_vault::<T1>(market).balance, amount);
//             let (_, nft_event, nft_id_event) = deliverNft::<T0, T1>(market, policy_vault, nft_id, &mut split_balance, final_recipient, version, ctx);
//             book::make_and_fire_event_filled(
//                 object::id(market),
//                 &bill,
//                 nft_event,
//                 nft_id_event
//             );
//             deposit_balance::<T1>(market, split_balance);
//             update_analysis_exec(market, amount, exec_param, analysis_exec_param);
//         };

//         if (option::is_some(&expired_bill_option)) {
//             let expired_bill = option::extract(&mut expired_bill_option);
//             let (is_refund, refund_amount, refund_exec_param, nft_id) = book::expired_info(&expired_bill);
//             if (is_refund) {
//                 refund_coin::<T1>(balance_vault::<T1>(market), refund_exec_param, refund_amount, ctx);
//             } else {
//                 public_kiosk::delistAndTake::<T0, T1>(
//                     pkiosk_mut(market),
//                     *option::borrow(&nft_id),
//                     version,
//                     ctx
//                 );
//             };
//         };

//         if (refund_amount > 0) {
//             refund_coin::<T1>(balance_vault::<T1>(market), refund_amount, refund_address, ctx);
//         };
//     }

//     fun deliver_cross_clt<T0: store + key, T1>(
//         clt_vault: &mut clt::CltVault<T1>,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         bill_option: option::Option<book::Bill>,
//         expired_bill_option: option::Option<book::ExpiredBill>,
//         refund_address: address,
//         refund_amount: u64,
//         market: &mut Market,
//         version: &version::Version,
//         analysis_exec_param: u64,
//         ctx: &mut tx_context::TxContext
//     ) {
//         if (option::is_some(&bill_option)) {
//             let bill = option::extract(&mut bill_option);
//             let (is_sender, bill_creator, bill_amount, bill_exec_param, bill_clt) = book::fill_info(&bill);
//             let recipient = if (is_sender) {
//                 tx_context::sender(ctx)
//             } else {
//                 bill_creator
//             };
//             let split_balance = balance::split(&mut balance_vault::<T1>(market).balance, bill_amount);
//             let (_, clt_event, clt_result) = deliverNftClt(market, policy_vault, clt_vault, bill_clt, &mut split_balance, recipient, version, ctx);
//             book::make_and_fire_event_filled(
//                 object::id(market),
//                 &bill,
//                 clt_event,
//                 clt_result
//             );
//             deposit_balance(market, split_balance);
//             update_analysis_exec(market, bill_amount, bill_exec_param, analysis_exec_param);
//         };

//         if (option::is_some(&expired_bill_option)) {
//             let expired_bill = option::extract(&mut expired_bill_option);
//             let (is_refund, refund_amount, refund_exec_param, expired_bill_id) = book::expired_info(&expired_bill);
//             if (is_refund) {
//                 refund_balance(clt_vault, market, refund_exec_param, refund_amount, ctx);
//             } else {
//                 public_kiosk::delistAndTake(
//                     pkiosk_mut(market),
//                     *option::borrow(&expired_bill_id),
//                     version,
//                     ctx
//                 );
//             };
//         };

//         if (refund_amount > 0) {
//             refund_balance(clt_vault, market, refund_amount, refund_address, ctx);
//         };
//     }

//     fun deposit_balance<T>(
//         market: &mut Market,
//         balance: balance::Balance<T>
//     ) {
//         let vault_balance = &mut balance_vault<T>(market).balance;
//         balance::join(vault_balance, balance);
//     }

//     fun deposit_coin<T>(
//         market: &mut Market,
//         coin: coin::Coin<T>
//     ) {
//         let balance = balance_vault<T>(market).balance;
//         let coin_balance = coin::into_balance(coin);
//         balance::join(&mut balance, coin_balance);
//     }

//     fun emitMarketAnal(
//         analysis: &Analysis,
//         market_id: object::ID,
//         timestamp: u64
//     ) {
//         let market_analysis = MarketAnalysis {
//             id: market_id,
//             vol: analysis.vol,
//             floor: analysis.floor,
//             ceil: analysis.ceil,
//             bids_size: analysis.bids_size,
//             asks_size: analysis.asks_size,
//             timestamp,
//         };
//         event::emit<MarketAnalysis>(market_analysis);
//     }

//     fun init(
//         market: MARKET,
//         ctx: &mut tx_context::TxContext
//     ) {
//         let admin_cap = MarketAdminCap { id: object::new(ctx) };
//         transfer::transfer(admin_cap, tx_context::sender(ctx));

//         let treasure_cap = MarketTreasureCap { id: object::new(ctx) };
//         transfer::transfer(treasure_cap, tx_context::sender(ctx));
//     }

//     fun orderbook(
//         market: &Market
//     ): &book::Book {
//         dynamic_field::borrow<
//             type_name::TypeName,
//             book::Book
//         >(&market.id, type_name::get<book::Book>())
//     }

//     fun orderbook_mut(
//         market: &mut Market
//     ): &mut book::Book {
//         dynamic_field::borrow_mut<type_name::TypeName, book::Book>(
//             &mut market.id,
//             type_name::get<book::Book>()
//         )
//     }

//     fun pair<T0: store + key, T1>(): Pair {
//         Pair {
//             nft: type_name::get<T0>(),
//             token: type_name::get<T1>(),
//         }
//     }

//     fun pkiosk_mut(
//         market: &mut Market
//     ): &mut public_kiosk::PublicKiosk {
//         dynamic_field::borrow_mut<
//             type_name::TypeName,
//             public_kiosk::PublicKiosk
//         >(
//             &mut market.id,
//             type_name::get<
//                 public_kiosk::PublicKiosk
//             >()
//         )
//     }

//     fun refund_balance<T>(
//         clt_vault: &mut clt::CltVault<T>,
//         market: &mut Market,
//         amount: u64,
//         recipient: address,
//         ctx: &mut tx_context::TxContext
//     ) {
//         let split_balance = balance::split(&mut balance_vault<T>(market).balance, amount);
//         clt::withdrawTo(
//             split_balance,
//             recipient,
//             clt_vault,
//             ctx
//         );
//     }

//     fun refund_coin<T>(
//         balance_manager: &mut BalanceManager<T>,
//         amount: u64,
//         recipient: address,
//         ctx: &mut tx_context::TxContext
//     ) {
//         let split_balance = balance::split(&mut balance_manager.balance, amount);
//         let coin = coin::from_balance(split_balance, ctx);
//         transfer::public_transfer(coin, recipient);
//     }

//     fun update_analysis_bsize(
//         market: &mut Market,
//         timestamp: u64
//     ) {
//         let (bids_size, asks_size) = book::book_size(orderbook(market));
//         let analysis = analysis_mut(market);
//         analysis.bids_size = bids_size;
//         analysis.asks_size = asks_size;
//         emitMarketAnal(analysis, object::id(market), timestamp);
//     }

//     fun update_analysis_exec(
//         market: &mut Market,
//         volume: u64,
//         price: u64,
//         timestamp: u64
//     ) {
//         let analysis = analysis_mut(market);
//         analysis.vol = analysis.vol + (volume as u128);
//         analysis.floor = u64::min(analysis.floor, price);
//         analysis.ceil = u64::max(analysis.ceil, price);
//         emitMarketAnal(analysis, object::id(market), timestamp);
//     }

//     fun validateMarket0<T0: store + key, T1>(
//         market: &Market
//     ) {
//         assert!(market.pair == pair<T0, T1>(), 6001);
//     }

//     fun validateMarket2<T0: store + key, T1>(
//         market: &Market,
//         policy_vault: &payment_policy::PolicyVault<T0>,
//         is_coin_or_clt: bool
//     ) {
//         assert!(
//             market.pair == pair<T0, T1>() && 
//             market.policy == object::id(policy_vault),
//             6001
//         );
//         assert!(market.coin_or_clt == is_coin_or_clt, 6004);
//     }

//     fun validateMarket<T0: store + key, T1>(
//         is_bid: bool,
//         market: &mut Market,
//         policy_vault: &payment_policy::PolicyVault<T0>,
//         coin_or_clt: bool
//     ) {
//         assert!(
//             market.pair == pair<T0, T1>() && 
//             market.policy == object::id(policy_vault),
//             6001
//         );
//         assert!(market.coin_or_clt == coin_or_clt, 6004);

//         let max_order = config(market).max_order;
//         let analysis = analysis_mut(market);

//         let is_valid = if (is_bid && analysis.bids_size <= max_order) {
//             true
//         } else {
//             let is_ask_valid = !is_bid && analysis.asks_size <= max_order;
//             is_ask_valid
//         };

//         assert!(is_valid, 6008);
//     }

//     fun validateOfferPrice(
//         market: &Market,
//         offer_price: u64
//     ) {
//         let floor_price = analysis(market).floor;
//         let min_offer_price = math::div(
//             math::mul(
//                 floor_price,
//                 config(market).min_offer_per
//             ),
//             constants::max_fee()
//         );
//         assert!(
//             floor_price >= 0 && offer_price >= min_offer_price,
//             6010
//         );
//     }

//     public fun createMarket<T0: store + key, T1>(
//         admin_cap: &MarketAdminCap,
//         policy_vault: &payment_policy::PolicyVault<T0>,
//         coin_or_clt: bool,
//         tick_size: u64,
//         min_size: u64,
//         base_fee: u64,
//         max_order: u64,
//         min_offer_per: u64,
//         allow_self_match: bool,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         version::checkVersion(version, 1);
//         assert!(
//             tick_size > 0 && min_size > 0 && base_fee <= constants::max_fee() &&
//             max_order > 0 && min_offer_per <= constants::max_fee(),
//             6009
//         );

//         let pair = pair<T0, T1>();
//         let market = Market {
//             id: object::new(ctx),
//             policy: object::id(policy_vault),
//             pair,
//             coin_or_clt,
//         };

//         let balance_manager = BalanceManager<T1> {
//             balance: balance::zero<T1>(),
//             fee: balance::zero<T1>(),
//         };

//         let config = Config {
//             tick_size,
//             min_size,
//             base_fee,
//             allow_self_match,
//             max_order,
//             min_offer_per,
//         };

//         let market_created_event = MarketCreated {
//             id: object::id(&market),
//             bid: type_name::into_string(pair.token),
//             ask: type_name::into_string(pair.nft),
//             coin_or_clt,
//             tick_size,
//             min_size,
//             base_fee,
//             max_order,
//             allow_self_match,
//             policy: object::id_address(policy_vault),
//         };

//         event::emit(market_created_event);

//         dynamic_field::add(
//             &mut market.id,
//             type_name::get<book::Book>(),
//             book::empty(base_fee, tick_size, min_size, ctx)
//         );

//         dynamic_field::add(
//             &mut market.id,
//             type_name::get<BalanceManager<T1>>(),
//             balance_manager
//         );

//         dynamic_field::add(
//             &mut market.id,
//             type_name::get<public_kiosk::PublicKiosk>(),
//             public_kiosk::createPublicKiosk<T0, T1>(version, ctx)
//         );

//         dynamic_field::add(
//             &mut market.id,
//             type_name::get<Config>(),
//             config
//         );

//         let analysis = Analysis {
//             floor: 0,
//             ceil: 0,
//             vol: 0,
//             bids_size: 0,
//             asks_size: 0,
//         };

//         dynamic_field::add(
//             &mut market.id,
//             type_name::get<Analysis>(),
//             analysis
//         );

//         transfer::public_share_object(market);

//         cap_vault::createVault<MarketAdminCap>(ctx);
//         cap_vault::createVault<MarketTreasureCap>(ctx);
//     }

//     public fun sell_limit<T0: store + key, T1>(
//         market: &mut Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         item: T0,
//         price: u64,
//         duration_hours: u64,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ): u128 {
//         version::checkVersion(version, 1);
//         let current_time = clock::timestamp_ms(clock);
//         validateMarket<T0, T1>(false, market, policy_vault, true);
//         let item_id = object::id(&item);
//         let adjusted_price = price - price % config_mut(market).tick_size;
//         let expiration_time = if (duration_hours > 0) {
//             current_time + constants::one_hour_ms() * duration_hours
//         } else {
//             0
//         };
//         public_kiosk::placeAndList<T0, T1>(
//             pkiosk_mut(market),
//             item,
//             adjusted_price,
//             version,
//             ctx
//         );
//         let order_info = book::make_order_info(
//             object::id(market),
//             tx_context::sender(ctx),
//             1,
//             false,
//             option::some(item_id),
//             adjusted_price,
//             constants::ord_limit(),
//             0,
//             expiration_time,
//             constants::atomic()
//         );
//         let order = book::place_order(
//             orderbook_mut(market),
//             &order_info,
//             config(market).allow_self_match,
//             current_time
//         );
//         let order_id = book::order_id(&order);
//         public_kiosk::bindOrderId(
//             pkiosk_mut(market),
//             item_id,
//             order_id
//         );
//         deliver<T0, T1>(order, market, policy_vault, version, current_time, ctx);
//         update_analysis_bsize(market, current_time);
//         order_id
//     }

//     public fun sell_limit_clt<T0: store + key, T1>(
//         market: &mut Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         clt_vault: &mut clt::CltVault<T1>,
//         asset: T0,
//         price: u64,
//         duration: u64,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ): u128 {
//         version::checkVersion(version, 1);
//         validateMarket<T0, T1>(false, market, policy_vault, false);

//         let asset_id = object::id(&asset);
//         let timestamp = clock::timestamp_ms(clock);
//         let adjusted_price = price - (price % config_mut(market).tick_size);

//         let expiration_time = if (duration > 0) {
//             timestamp + constants::one_hour_ms() * duration
//         } else {
//             0
//         };

//         public_kiosk::placeAndList(
//             pkiosk_mut(market),
//             asset,
//             adjusted_price,
//             version,
//             ctx
//         );

//         let order_info = book::make_order_info(
//             object::id(market),
//             tx_context::sender(ctx),
//             1,
//             false,
//             option::some(asset_id),
//             adjusted_price,
//             constants::ord_limit(),
//             0,
//             expiration_time,
//             constants::atomic()
//         );

//         let order = book::place_order(
//             orderbook_mut(market),
//             &order_info,
//             config(market).allow_self_match,
//             timestamp
//         );

//         let order_id = book::order_id(&order);

//         public_kiosk::bindOrderId(
//             pkiosk_mut(market),
//             asset_id,
//             order_id
//         );

//         deliver_clt(order, market, policy_vault, clt_vault, version, timestamp, ctx);
//         update_analysis_bsize(market, timestamp);

//         order_id
//     }

//     public fun sell_flash<T0: store + key, T1>(
//         market: &mut Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         item: T0,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ): u128 {
//         version::checkVersion(version, 1);
//         validateMarket<T0, T1>(false, market, policy_vault, true);

//         let item_id = object::id(&item);
//         let timestamp = clock::timestamp_ms(clock);

//         public_kiosk::placeAndList(
//             pkiosk_mut(market),
//             item,
//             0,
//             version,
//             ctx
//         );

//         let order_info = book::make_order_info(
//             object::id(market),
//             tx_context::sender(ctx),
//             1,
//             false,
//             option::some(item_id),
//             0,
//             constants::ord_market(),
//             0,
//             0,
//             constants::atomic()
//         );

//         let order = book::place_order(
//             orderbook_mut(market),
//             &order_info,
//             config(market).allow_self_match,
//             timestamp
//         );

//         let order_id = book::order_id(&order);

//         public_kiosk::bindOrderId(
//             pkiosk_mut(market),
//             item_id,
//             order_id
//         );

//         deliver<T0, T1>(order, market, policy_vault, version, timestamp, ctx);
//         update_analysis_bsize(market, timestamp);

//         order_id
//     }

//     public fun sell_flash_clt<T0: store + key, T1>(
//         market: &mut Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         clt_vault: &mut clt::CltVault<T1>,
//         asset: T0,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ): u128 {
//         version::checkVersion(version, 1);
//         validateMarket<T0, T1>(false, market, policy_vault, false);

//         let asset_id = object::id(&asset);
//         let timestamp = clock::timestamp_ms(clock);

//         public_kiosk::placeAndList(
//             pkiosk_mut(market),
//             asset,
//             0,
//             version,
//             ctx
//         );

//         let order_info = book::make_order_info(
//             object::id(market),
//             tx_context::sender(ctx),
//             1,
//             false,
//             option::some(asset_id),
//             0,
//             constants::ord_market(),
//             0,
//             0,
//             constants::atomic()
//         );

//         let order = book::place_order(
//             orderbook_mut(market),
//             &order_info,
//             config(market).allow_self_match,
//             timestamp
//         );

//         let order_id = book::order_id(&order);

//         public_kiosk::bindOrderId(
//             pkiosk_mut(market),
//             asset_id,
//             order_id
//         );

//         deliver_clt<T0, T1>(
//             order,
//             market,
//             policy_vault,
//             clt_vault,
//             version,
//             timestamp,
//             ctx
//         );

//         update_analysis_bsize(market, timestamp);

//         order_id
//     }

//     public fun cancel_sell<T0: store + key, T1>(
//         market: &mut Market,
//         order_ids: vector<object::ID>,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         version::checkVersion(version, 1);
//         validateMarket0<T0, T1>(market);
//         let remaining_orders = vector::length(&order_ids);

//         while (remaining_orders > 0) {
//             let current_index = remaining_orders - 1;
//             remaining_orders = current_index;

//             let order_id = *vector::borrow(&order_ids, current_index);
//             assert!(
//                 tx_context::sender(ctx) ==
//                 public_kiosk::orderOwner(
//                     pkiosk_mut(market),
//                     order_id
//                 ),
//                 6007
//             );

//             let delisted_order = public_kiosk::delistAndTake<T0, T1>(
//                 pkiosk_mut(market),
//                 order_id,
//                 version,
//                 ctx
//             );

//             book::cancel_order(
//                 orderbook_mut(market),
//                 delisted_order
//             );
//         };
//     }

//     public fun cancel_sell_ordid<T0: store + key, T1>(
//         market: &mut Market,
//         order_ids: vector<u128>,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         version::checkVersion(version, 1);
//         validateMarket0<T0, T1>(market);
//         let remaining_orders = vector::length(&order_ids);

//         while (remaining_orders > 0) {
//             remaining_orders = remaining_orders - 1;

//             let order = book::cancel_order(
//                 orderbook_mut(market),
//                 vector::pop_back(&mut order_ids)
//             );

//             let (is_filled, owner, _, optional_object_id, _) = book::order_info(&order);

//             let object_id_option = optional_object_id;

//             assert!(owner == tx_context::sender(ctx), 6007);
//             assert!(!is_filled && option::is_some(&object_id_option), 6003);

//             public_kiosk::delistAndTake(
//                 pkiosk_mut(market),
//                 option::extract(&mut object_id_option),
//                 version,
//                 ctx
//             );
//         };
//     }

//     public fun buy_limit<T0: store + key, T1>(
//         market: &mut Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         payment_coin: coin::Coin<T1>,
//         offer_price: u64,
//         duration_hours: u64,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ): u128 {
//         version::checkVersion(version, 1);
//         validateMarket<T0, T1>(false, market, policy_vault, true);
//         validateOfferPrice(market, offer_price);

//         let current_timestamp = clock::timestamp_ms(clock);
//         let payment_value = coin::value(&payment_coin);
//         let adjusted_price = offer_price - (offer_price % config_mut(market).tick_size);
//         let expiration_time = if (duration_hours > 0) {
//             current_timestamp + constants::one_hour_ms() * duration_hours
//         } else {
//             0
//         };

//         assert!(adjusted_price > 0 && payment_value >= adjusted_price, 6003);

//         deposit_coin<T1>(market, payment_coin);

//         let order_info = book::make_order_info(
//             object::id(market),
//             tx_context::sender(ctx),
//             payment_value,
//             true,
//             option::none<object::ID>(),
//             adjusted_price,
//             constants::ord_limit(),
//             0,
//             expiration_time,
//             constants::ice_berge()
//         );

//         let placed_order = book::place_order(
//             orderbook_mut(market),
//             &order_info,
//             config(market).allow_self_match,
//             current_timestamp
//         );

//         deliver<T0, T1>(placed_order, market, policy_vault, version, current_timestamp, ctx);
//         update_analysis_bsize(market, current_timestamp);

//         book::order_id(&placed_order)
//     }

//     public fun buy_limit_clt<T0: store + key, T1>(
//         market: &mut Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         clt_vault: &mut clt::CltVault<T1>,
//         balance: balance::Balance<T1>,
//         deposit_proof: clt::DepositProof,
//         offer_price: u64,
//         ice_berge: u64,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ): u128 {
//         version::checkVersion(version, 1);
//         clt::verifyDepositProof(&balance, deposit_proof);
//         validateMarket<T0, T1>(true, market, policy_vault, false);
//         validateOfferPrice(market, offer_price);

//         let timestamp = clock::timestamp_ms(clock);
//         let balance_value = balance::value(&balance);
//         let adjusted_price = offer_price - (offer_price % config_mut(market).tick_size);
//         let expiration_time = if (ice_berge > 0) {
//             timestamp + constants::ten_days_ms()
//         } else {
//             0
//         };

//         assert!(adjusted_price > 0 && balance_value >= adjusted_price, 6003);

//         deposit_balance(market, balance);

//         let order_info = book::make_order_info(
//             object::id(market),
//             tx_context::sender(ctx),
//             balance_value,
//             true,
//             option::none(),
//             adjusted_price,
//             constants::ord_limit(),
//             0,
//             expiration_time,
//             constants::ice_berge()
//         );

//         let order = book::place_order(
//             orderbook_mut(market),
//             &order_info,
//             config(market).allow_self_match,
//             timestamp
//         );

//         deliver_clt(order, market, policy_vault, clt_vault, version, timestamp, ctx);
//         update_analysis_bsize(market, timestamp);

//         book::order_id(&order)
//     }

//     public fun buy_flash<T0: store + key, T1>(
//         market: &mut Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         payment_coin: coin::Coin<T1>,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ): u128 {
//         version::checkVersion(version, 1);
//         validateMarket<T0, T1>(true, market, policy_vault, true);

//         let timestamp = clock::timestamp_ms(clock);
//         let payment_value = coin::value(&payment_coin);
//         assert!(payment_value > 0, 6003);

//         deposit_coin<T1>(market, payment_coin);

//         let order_info = book::make_order_info(
//             object::id(market),
//             tx_context::sender(ctx),
//             payment_value,
//             true,
//             option::none<object::ID>(),
//             0,
//             constants::ord_market(),
//             0,
//             0,
//             constants::ice_berge()
//         );

//         let order = book::place_order(
//             orderbook_mut(market),
//             &order_info,
//             config(market).allow_self_match,
//             timestamp
//         );

//         deliver<T0, T1>(order, market, policy_vault, version, timestamp, ctx);
//         update_analysis_bsize(market, timestamp);

//         book::order_id(&order)
//     }

//     public fun buy_flash_clt<T0: store + key, T1>(
//         market: &mut Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         clt_vault: &mut clt::CltVault<T1>,
//         balance: balance::Balance<T1>,
//         deposit_proof: clt::DepositProof,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ): u128 {
//         version::checkVersion(version, 1);
//         validateMarket<T0, T1>(true, market, policy_vault, false);
//         clt::verifyDepositProof(&balance, deposit_proof);
        
//         let timestamp = clock::timestamp_ms(clock);
//         let balance_value = balance::value(&balance);
//         assert!(balance_value > 0, 6003);
        
//         deposit_balance<T1>(market, balance);
        
//         let order_info = book::make_order_info(
//             object::id(market),
//             tx_context::sender(ctx),
//             balance_value,
//             true,
//             option::none<object::ID>(),
//             0,
//             constants::ord_market(),
//             0,
//             0,
//             constants::ice_berge()
//         );
        
//         let order = book::place_order(
//             orderbook_mut(market),
//             &order_info,
//             config(market).allow_self_match,
//             timestamp
//         );
        
//         deliver_clt<T0, T1>(order, market, policy_vault, clt_vault, version, timestamp, ctx);
//         update_analysis_bsize(market, timestamp);
        
//         book::order_id(&order)
//     }

//     public fun cancel_buy<T0: store + key, T1>(
//         market: &mut Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         order_ids: vector<u128>,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         version::checkVersion(version, 1);
//         validateMarket2<T0, T1>(market, policy_vault, true);

//         let remaining_orders = vector::length(&order_ids);

//         while (remaining_orders > 0) {
//             let current_index = remaining_orders - 1;
//             remaining_orders = current_index;

//             let order_id = *vector::borrow(&order_ids, current_index);
//             let (is_buy, owner, _, _, _) = book::order_info(
//                 book::order(orderbook_mut(market), order_id)
//             );

//             assert!(owner == tx_context::sender(ctx) && is_buy, 6003);

//             let canceled_order = book::cancel_order(
//                 orderbook_mut(market),
//                 order_id
//             );

//             refund_coin<T1>(
//                 balance_vault<T1>(market),
//                 book::remain_balance(&canceled_order),
//                 tx_context::sender(ctx),
//                 ctx
//             );
//         };
//     }

//     public fun cancel_buy_clt<T0: store + key, T1>(
//         market: &mut Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         clt_vault: &mut clt::CltVault<T1>,
//         order_ids: vector<u128>,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         version::checkVersion(version, 1);
//         validateMarket2<T0, T1>(market, policy_vault, false);

//         let remaining_orders = vector::length(&order_ids);

//         while (remaining_orders > 0) {
//             let current_index = remaining_orders - 1;
//             remaining_orders = current_index;

//             let order_id = *vector::borrow(&order_ids, current_index);
//             let (is_active, owner, _, _, _) = book::order_info(
//                 book::order(orderbook_mut(market), order_id)
//             );

//             assert!(owner == tx_context::sender(ctx) && is_active, 6003);

//             let canceled_order = book::cancel_order(
//                 orderbook_mut(market),
//                 order_id
//             );

//             refund_balance<T1>(
//                 clt_vault,
//                 market,
//                 book::remain_balance(&canceled_order),
//                 tx_context::sender(ctx),
//                 ctx
//             );
//         };
//     }

//     public fun buy_cross_clt<T0: store + key, T1>(
//         market: &mut Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         sui_coin: &mut coin::Coin<sui::SUI>,
//         amount: u64,
//         clt_vault: &mut clt::CltVault<T1>,
//         clt_balance: balance::Balance<T1>,
//         deposit_proof: clt::DepositProof,
//         object_id: object::ID,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         clt::verifyDepositProof<T1>(&clt_balance, deposit_proof);
//         buy_cross_clt_int<T0, T1>(
//             market,
//             policy_vault,
//             sui_coin,
//             amount,
//             clt_vault,
//             clt_balance,
//             object_id,
//             clock,
//             version,
//             ctx
//         );
//     }

//     public fun buy_cross<T0: store + key, T1>(
//         market: &mut Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         payment_coin: coin::Coin<T1>,
//         nft_id: object::ID,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         version::checkVersion(version, 1);
//         validateMarket<T0, T1>(true, market, policy_vault, true);

//         let payment_value = coin::value(&payment_coin);
//         let order_price = public_kiosk::orderPrice(pkiosk_mut(market), nft_id);
//         assert!(payment_value >= order_price, 6005);

//         let order_id = public_kiosk::orderIdFromNft(pkiosk_mut(market), nft_id);
//         let current_timestamp = clock::timestamp_ms(clock);
//         assert!(
//             !book::order_expired(orderbook_mut(market), order_id, current_timestamp),
//             6006
//         );

//         deposit_coin<T1>(market, payment_coin);

//         let order_info = book::make_order_info(
//             object::id(market),
//             tx_context::sender(ctx),
//             payment_value,
//             true,
//             option::some(nft_id),
//             0,
//             constants::ord_cross(),
//             order_id,
//             0,
//             constants::ice_berge()
//         );

//         let (filled_qty, remaining_qty, filled_price, filled_fee) = book::place_cross(
//             orderbook_mut(market),
//             &order_info,
//             config(market).allow_self_match,
//             current_timestamp
//         );

//         deliver_cross<T0, T1>(
//             policy_vault,
//             filled_qty,
//             remaining_qty,
//             filled_price,
//             filled_fee,
//             market,
//             version,
//             current_timestamp,
//             ctx
//         );

//         update_analysis_bsize(market, current_timestamp);
//     }

//     public fun buy_cross_clt_orderid<T0: store + key, T1>(
//         market: &mut Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         sui_coin: &mut coin::Coin<sui::SUI>,
//         rebate_fee: u64,
//         clt_vault: &mut clt::CltVault<T1>,
//         clt_balance: balance::Balance<T1>,
//         deposit_proof: clt::DepositProof,
//         order_id: u128,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         clt::verifyDepositProof<T1>(&clt_balance, deposit_proof);
//         version::checkVersion(version, 1);
//         validateMarket<T0, T1>(true, market, policy_vault, false);
//         let (is_sell, _, order_price, order_quantity, order_value) = book::order_info(
//             book::order(orderbook_mut(market), order_id)
//         );
//         assert!(order_quantity > 0 && !is_sell, 6011);
//         let clt_balance_value = balance::value(&clt_balance);
//         assert!(clt_balance_value >= order_value, 6005);
//         let current_timestamp = clock::timestamp_ms(clock);
//         assert!(
//             !book::order_expired(orderbook_mut(market), order_id, current_timestamp),
//             6006
//         );
//         deposit_balance<T1>(market, clt_balance);
//         let order_info = book::make_order_info(
//             object::id(market),
//             tx_context::sender(ctx),
//             clt_balance_value,
//             true,
//             order_price,
//             0,
//             constants::ord_cross(),
//             order_id,
//             0,
//             constants::ice_berge()
//         );
//         let (matched_quantity, matched_value, matched_price, matched_fee) = book::place_cross(
//             orderbook_mut(market),
//             &order_info,
//             config(market).allow_self_match,
//             current_timestamp
//         );
//         let matched_quantity_final = matched_quantity;
//         deliver_cross_clt<T0, T1>(
//             clt_vault,
//             policy_vault,
//             matched_quantity_final,
//             matched_value,
//             matched_price,
//             matched_fee,
//             market,
//             version,
//             current_timestamp,
//             ctx
//         );
//         update_analysis_bsize(market, current_timestamp);
//         deliverRebateFee(sui_coin, rebate_fee, &matched_quantity_final, ctx);
//     }

//     public fun buy_cross_orderid<T0: store + key, T1>(
//         market: &mut Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         payment_coin: coin::Coin<T1>,
//         order_id: u128,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         version::checkVersion(version, 1);
//         validateMarket<T0, T1>(true, market, policy_vault, true);

//         let (is_sell, _, price, quantity, required_payment) = book::order_info(
//             book::order(orderbook_mut(market), order_id)
//         );

//         assert!(quantity > 0 && !is_sell, 6011);

//         let payment_value = coin::value(&payment_coin);
//         assert!(payment_value >= required_payment, 6005);

//         let current_timestamp = clock::timestamp_ms(clock);
//         assert!(
//             !book::order_expired(
//                 orderbook_mut(market),
//                 order_id,
//                 current_timestamp
//             ),
//             6006
//         );

//         deposit_coin<T1>(market, payment_coin);

//         let order_info = book::make_order_info(
//             object::id(market),
//             tx_context::sender(ctx),
//             payment_value,
//             true,
//             price,
//             0,
//             constants::ord_cross(),
//             order_id,
//             0,
//             constants::ice_berge()
//         );

//         let (matched_quantity, matched_price, remaining_quantity, remaining_price) = book::place_cross(
//             orderbook_mut(market),
//             &order_info,
//             config(market).allow_self_match,
//             current_timestamp
//         );

//         deliver_cross<T0, T1>(
//             policy_vault,
//             matched_quantity,
//             matched_price,
//             remaining_quantity,
//             remaining_price,
//             market,
//             version,
//             current_timestamp,
//             ctx
//         );

//         update_analysis_bsize(market, current_timestamp);
//     }

//     public fun sweep<T0: store + key, T1>(
//         market: &mut Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         object_ids: vector<object::ID>,
//         payment_coin: &mut coin::Coin<T1>,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         version::checkVersion(version, 1);
//         validateMarket<T0, T1>(true, market, policy_vault, true);
//         let remaining = vector::length(&object_ids);
//         while (remaining > 0) {
//             let index = remaining - 1;
//             remaining = index;
//             let object_id = *vector::borrow(&object_ids, index);
//             let order_price = public_kiosk::orderPrice(pkiosk_mut(market), object_id);
//             let split_coin = coin::split(payment_coin, order_price, ctx);
//             buy_cross<T0, T1>(market, policy_vault, split_coin, object_id, clock, version, ctx);
//         };
//     }

//     public fun sweep_clt<T0: store + key, T1>(
//         market: &mut Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         sui_coin: &mut coin::Coin<sui::SUI>,
//         arg3: u64,
//         clt_vault: &mut clt::CltVault<T1>,
//         object_ids: vector<object::ID>,
//         clt_balance: balance::Balance<T1>,
//         deposit_proof: clt::DepositProof,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         version::checkVersion(version, 1);
//         validateMarket<T0, T1>(true, market, policy_vault, false);
//         clt::verifyDepositProof(&clt_balance, deposit_proof);
//         let remaining_objects = vector::length(&object_ids);

//         while (remaining_objects > 0) {
//             let current_index = remaining_objects - 1;
//             remaining_objects = current_index;
//             let object_id = *vector::borrow(&object_ids, current_index);
//             let order_price = public_kiosk::orderPrice(pkiosk_mut(market), object_id);
//             let split_balance = balance::split(&mut clt_balance, order_price);
//             buy_cross_clt_int<T0, T1>(
//                 market,
//                 policy_vault,
//                 sui_coin,
//                 arg3,
//                 clt_vault,
//                 split_balance,
//                 object_id,
//                 clock,
//                 version,
//                 ctx
//             );
//         };

//         clt::withdrawTo(
//             clt_balance,
//             tx_context::sender(ctx),
//             clt_vault,
//             ctx
//         );
//     }

//     public fun sweep_clt_orderids<T0: store + key, T1>(
//         market: &mut Market,
//         policy_vault: &mut payment_policy::PolicyVault<T0>,
//         sui_coin: &mut coin::Coin<sui::SUI>,
//         arg3: u64,
//         clt_vault: &mut clt::CltVault<T1>,
//         order_ids: vector<u128>,
//         clt_balance: balance::Balance<T1>,
//         deposit_proof: clt::DepositProof,
//         clock: &clock::Clock,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         version::checkVersion(version, 1);
//         validateMarket<T0, T1>(true, market, policy_vault, false);
//         clt::verifyDepositProof<T1>(&clt_balance, deposit_proof);
//         let remaining_orders = vector::length<u128>(&order_ids);

//         while (remaining_orders > 0) {
//             let current_index = remaining_orders - 1;
//             remaining_orders = current_index;

//             let order_id = *vector::borrow<u128>(&order_ids, current_index);
//             let order_nft = book::order_nft(orderbook(market), order_id);
//             assert!(option::is_some<object::ID>(&order_nft), 6003);

//             let order_object_id = *option::borrow<object::ID>(&order_nft);
//             let order_price = public_kiosk::orderPrice(pkiosk_mut(market), order_object_id);
//             let split_balance = balance::split<T1>(&mut clt_balance, order_price);

//             buy_cross_clt_int<T0, T1>(
//                 market,
//                 policy_vault,
//                 sui_coin,
//                 arg3,
//                 clt_vault,
//                 split_balance,
//                 order_object_id,
//                 clock,
//                 version,
//                 ctx
//             );
//         };

//         clt::withdrawTo<T1>(
//             clt_balance,
//             tx_context::sender(ctx),
//             clt_vault,
//             ctx
//         );
//     }

//     public fun withdraw_fee<T0: store + key, T1>(
//         market_treasure_cap: &MarketTreasureCap,
//         market: &mut Market,
//         version: &version::Version
//     ): balance::Balance<T1> {
//         version::checkVersion(version, 1);
//         assert!(pair<T0, T1>() == market.pair, 6001);
//         let fee_vault = &mut balance_vault<T1>(market).fee;
//         balance::split(fee_vault, balance::value(fee_vault))
//     }

//     public fun withdraw_fee_clt<T0: store + key, T1>(
//         market_treasure_cap: &MarketTreasureCap,
//         clt_vault: &mut clt::CltVault<T1>,
//         recipient: address,
//         market: &mut Market,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ) {
//         version::checkVersion(version, 1);
//         assert!(pair<T0, T1>() == market.pair, 6001);
//         let fee_balance = &mut balance_vault<T1>(market).fee;
//         let fee_value = balance::value(fee_balance);
//         let split_balance = balance::split(fee_balance, fee_value);
//         clt::withdrawTo(split_balance, recipient, clt_vault, ctx);
//     }
// }