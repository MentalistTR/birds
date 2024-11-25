// // Decompiled by SuiGPT
// module 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::book {

//     // ----- Use Statements -----

//     use sui::object;
//     use 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::big_vector;
//     use std::option;
//     use 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::obutils;
//     use 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::constants;
//     use std::vector;
//     use 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::math;
//     use sui::event;
//     use sui::tx_context;

//     // ----- Structs -----

//     struct Bill has copy, drop, store {
//         taker_is_bid: bool,
//         taker_ordid: u128,
//         maker_ordid: u128,
//         taker: address,
//         maker: address,
//         exec_price: u64,
//         exec_qty: u64,
//         timestamp: u64,
//         nft: object::ID,
//         maker_filled: bool,
//     }

//     struct Book has store {
//         base_fee: u64,
//         tick_size: u64,
//         min_size: u64,
//         asks: big_vector::BigVector<Order>,
//         bids: big_vector::BigVector<Order>,
//         next_bid_order_id: u64,
//         next_ask_order_id: u64,
//     }

//     struct ExpiredBill has copy, drop, store {
//         maker_is_bid: bool,
//         maker_order_id: u128,
//         maker: address,
//         exec_price: u64,
//         exec_qty: u64,
//         nft_id: option::Option<object::ID>,
//     }

//     struct Filled has copy, drop, store {
//         market_id: object::ID,
//         taker_is_bid: bool,
//         taker_ordid: u128,
//         maker_ordid: u128,
//         taker: address,
//         maker: address,
//         filled_value: u64,
//         filled_price: u64,
//         trading_fee: u64,
//         royalty_fee: u64,
//         nft: object::ID,
//         timestamp: u64,
//     }

//     struct Order has drop, store {
//         market_id: object::ID,
//         trader: address,
//         order_id: u128,
//         origin_qty: u64,
//         remain_qty: u64,
//         filled_qty: u64,
//         is_bid: bool,
//         nft_id: option::Option<object::ID>,
//         price: u64,
//         match_price: u64,
//         ord_type: u8,
//         cross_id: u128,
//         status: u8,
//         expire_timestamp: u64,
//         fill_mode: u8,
//     }

//     struct OrderEvent has copy, drop, store {
//         market: object::ID,
//         owner: address,
//         order_id: u128,
//         ord_type: u8,
//         nft_id: option::Option<object::ID>,
//         is_bid: bool,
//         remain_qty: u64,
//         filled_qty: u64,
//         origin_qty: u64,
//         price: u64,
//         match_price: u64,
//         state: u8,
//     }

//     struct OrderInfo has drop, store {
//         market_id: object::ID,
//         trader: address,
//         balance: u64,
//         is_bid: bool,
//         nft_id: option::Option<object::ID>,
//         price: u64,
//         ord_type: u8,
//         cross_id: u128,
//         fill_mode: u8,
//         expire_timestamp: u64,
//     }

//     struct TradeProof {
//         taker: address,
//         fills: vector<Bill>,
//         delists: vector<ExpiredBill>,
//         fill_limit_reached: bool,
//         order_id: u128,
//         inject: bool,
//         remain_qty: u64,
//         taker_is_bid: bool,
//         taker_nft: option::Option<object::ID>,
//     }

//     // ----- Functions -----

//     fun asks(
//         book: &Book
//     ): &big_vector::BigVector<Order> {
//         &book.asks
//     }

//     fun bids(
//         book: &Book
//     ): &big_vector::BigVector<Order> {
//         &book.bids
//     }

//     fun book_side(
//         book: &Book,
//         order_id: u128
//     ): &big_vector::BigVector<Order> {
//         let (is_bid, _, _) = obutils::decode_order_id(order_id);
//         if (is_bid) {
//             &book.bids
//         } else {
//             &book.asks
//         }
//     }

//     fun book_side_mut(
//         book: &mut Book,
//         order_id: u128
//     ): &mut big_vector::BigVector<Order> {
//         let (is_bid, _, _) = obutils::decode_order_id(order_id);
//         if (is_bid) {
//             &mut book.bids
//         } else {
//             &mut book.asks
//         }
//     }

//     fun get_order_id(
//         book: &mut Book,
//         is_bid: bool
//     ): u64 {
//         if (is_bid) {
//             book.next_bid_order_id = book.next_bid_order_id - 1;
//             book.next_bid_order_id
//         } else {
//             book.next_ask_order_id = book.next_ask_order_id + 1;
//             book.next_ask_order_id
//         }
//     }

//     fun inject_limit_order(
//         book: &mut Book,
//         order: Order
//     ) {
//         if (order.is_bid) {
//             big_vector::insert(
//                 &mut book.bids,
//                 order.order_id,
//                 order
//             );
//         } else {
//             big_vector::insert(
//                 &mut book.asks,
//                 order.order_id,
//                 order
//             );
//         };
//     }

//     fun inject_taker_order(
//         order: &Order,
//         trade_proof: &TradeProof
//     ): bool {
//         let condition = 
//             order.ord_type <= constants::ord_cross() || 
//             order.status >= constants::filled() || 
//             trade_proof.fill_limit_reached;
//         !condition
//     }

//     fun make_event(order: &Order): OrderEvent {
//         OrderEvent {
//             market: order.market_id,
//             owner: order.trader,
//             order_id: order.order_id,
//             ord_type: order.ord_type,
//             nft_id: order.nft_id,
//             is_bid: order.is_bid,
//             remain_qty: order.remain_qty,
//             filled_qty: order.filled_qty,
//             origin_qty: order.origin_qty,
//             price: order.price,
//             match_price: order.match_price,
//             state: order.status,
//         }
//     }

//     fun match_against_book(
//         book: &mut Book,
//         order: &mut Order,
//         trade_proof: &mut TradeProof,
//         is_bid: bool,
//         max_fill_amount: u64
//     ) {
//         let fills = &mut trade_proof.fills;
//         let delists = &mut trade_proof.delists;
//         let order_book_side = if (order.is_bid) {
//             &mut book.asks
//         } else {
//             &mut book.bids
//         };

//         let (current_slice, current_index) = if (is_bid) {
//             let (min_slice, min_index) = big_vector::min_slice<Order>(order_book_side);
//             (min_slice, min_index)
//         } else {
//             let (max_slice, max_index) = big_vector::max_slice<Order>(order_book_side);
//             (max_slice, max_index)
//         };

//         let slice_index = current_index;
//         let slice = current_slice;

//         while (!big_vector::slice_is_null(&slice)
//             && vector::length<Bill>(fills) < constants::max_fills()) {
//             if (!match_maker(
//                 order,
//                 big_vector::slice_borrow_mut<Order>(
//                     big_vector::borrow_slice_mut<Order>(
//                         order_book_side, slice
//                     ),
//                     slice_index
//                 ),
//                 fills,
//                 delists,
//                 is_bid,
//                 max_fill_amount
//             )) {
//                 break;
//             };

//             let (next_slice, next_index) = if (is_bid) {
//                 let (next_slice, next_index) = big_vector::next_slice<Order>(
//                     order_book_side, slice, slice_index
//                 );
//                 (next_slice, next_index)
//             } else {
//                 let (prev_slice, prev_index) = big_vector::prev_slice<Order>(
//                     order_book_side, slice, slice_index
//                 );
//                 (prev_slice, prev_index)
//             };

//             slice_index = next_index;
//             slice = next_slice;
//         };

//         let fills_length = vector::length<Bill>(fills);
//         while (fills_length > 0) {
//             let last_index = fills_length - 1;
//             fills_length = last_index;
//             let bill = vector::borrow_mut<Bill>(fills, last_index);
//             if (bill.maker_filled) {
//                 big_vector::remove<Order>(
//                     order_book_side, bill.maker_ordid
//                 );
//                 continue;
//             };
//         };

//         let delists_length = vector::length<ExpiredBill>(delists);
//         while (delists_length > 0) {
//             let last_index = delists_length - 1;
//             delists_length = last_index;
//             big_vector::remove<Order>(
//                 order_book_side,
//                 vector::borrow_mut<ExpiredBill>(delists, last_index).maker_order_id
//             );
//         };

//         if (vector::length<Bill>(fills) == constants::max_fills()) {
//             trade_proof.fill_limit_reached = true;
//         };
//     }

//     fun match_maker(
//         taker_order: &mut Order,
//         maker_order: &mut Order,
//         bills: &mut vector<Bill>,
//         expired_bills: &mut vector<ExpiredBill>,
//         allow_self_match: bool,
//         timestamp: u64
//     ): bool {
//         if (order_expired0(maker_order, timestamp)) {
//             setStatus(
//                 maker_order,
//                 constants::expired()
//             );
//             let expired_bill = ExpiredBill {
//                 maker_is_bid: !taker_order.is_bid,
//                 maker_order_id: maker_order.order_id,
//                 maker: maker_order.trader,
//                 exec_price: maker_order.price,
//                 exec_qty: maker_order.remain_qty,
//                 nft_id: maker_order.nft_id,
//             };
//             vector::push_back(expired_bills, expired_bill);
//             return true;
//         };

//         if (!allow_self_match && taker_order.trader == maker_order.trader) {
//             return true;
//         };

//         if (taker_order.is_bid) {
//             assert!(maker_order.remain_qty == 1, 10);
//             if (taker_order.ord_type == constants::ord_market()) {
//                 if (taker_order.remain_qty < maker_order.price) {
//                     setStatus(
//                         taker_order,
//                         constants::completed()
//                     );
//                     return false;
//                 };
//                 maker_order.remain_qty = 0;
//                 maker_order.filled_qty = 1;
//                 maker_order.match_price = maker_order.price;
//                 update_order_state(maker_order, timestamp);
//                 let exec_price = maker_order.price;
//                 taker_order.match_price = median_price(
//                     taker_order.match_price,
//                     taker_order.filled_qty,
//                     exec_price
//                 );
//                 taker_order.remain_qty = taker_order.remain_qty - exec_price;
//                 taker_order.filled_qty = taker_order.filled_qty + exec_price;
//                 update_order_state(taker_order, timestamp);
//                 let bill = Bill {
//                     taker_is_bid: true,
//                     taker_ordid: taker_order.order_id,
//                     maker_ordid: maker_order.order_id,
//                     taker: taker_order.trader,
//                     maker: maker_order.trader,
//                     exec_price: maker_order.price,
//                     exec_qty: exec_price,
//                     timestamp,
//                     nft: *option::borrow(&maker_order.nft_id),
//                     maker_filled: true,
//                 };
//                 vector::push_back(bills, bill);
//                 return true;
//             };
//             if (taker_order.remain_qty < taker_order.price) {
//                 setStatus(
//                     taker_order,
//                     constants::completed()
//                 );
//                 return false;
//             };
//             if (taker_order.price < maker_order.price) {
//                 update_order_state(taker_order, timestamp);
//                 return false;
//             };
//             let exec_price = maker_order.price;
//             taker_order.match_price = median_price(
//                 taker_order.match_price,
//                 taker_order.filled_qty,
//                 exec_price
//             );
//             taker_order.remain_qty = taker_order.remain_qty - exec_price;
//             taker_order.filled_qty = taker_order.filled_qty + exec_price;
//             update_order_state(taker_order, timestamp);
//             maker_order.remain_qty = 0;
//             maker_order.filled_qty = 1;
//             maker_order.match_price = maker_order.price;
//             update_order_state(maker_order, timestamp);
//             let bill = Bill {
//                 taker_is_bid: true,
//                 taker_ordid: taker_order.order_id,
//                 maker_ordid: maker_order.order_id,
//                 taker: taker_order.trader,
//                 maker: maker_order.trader,
//                 exec_price: maker_order.price,
//                 exec_qty: exec_price,
//                 timestamp,
//                 nft: *option::borrow(&maker_order.nft_id),
//                 maker_filled: true,
//             };
//             vector::push_back(bills, bill);
//             return true;
//         };

//         assert!(taker_order.remain_qty == 1, 10);
//         if (taker_order.ord_type == constants::ord_market()) {
//             let exec_price = maker_order.price;
//             maker_order.match_price = median_price(
//                 maker_order.match_price,
//                 maker_order.filled_qty,
//                 exec_price
//             );
//             maker_order.remain_qty = maker_order.remain_qty - exec_price;
//             maker_order.filled_qty = maker_order.filled_qty + exec_price;
//             update_order_state(maker_order, timestamp);
//             taker_order.remain_qty = 0;
//             taker_order.filled_qty = 1;
//             taker_order.match_price = maker_order.price;
//             update_order_state(taker_order, timestamp);
//             let bill = Bill {
//                 taker_is_bid: false,
//                 taker_ordid: taker_order.order_id,
//                 maker_ordid: maker_order.order_id,
//                 taker: taker_order.trader,
//                 maker: maker_order.trader,
//                 exec_price: maker_order.price,
//                 exec_qty: exec_price,
//                 timestamp,
//                 nft: *option::borrow(&taker_order.nft_id),
//                 maker_filled: maker_order.status == constants::filled(),
//             };
//             vector::push_back(bills, bill);
//             return false;
//         };
//         if (taker_order.price > maker_order.price) {
//             setStatus(
//                 taker_order,
//                 constants::live()
//             );
//             return false;
//         };
//         taker_order.remain_qty = 0;
//         taker_order.filled_qty = 1;
//         taker_order.match_price = maker_order.price;
//         update_order_state(taker_order, timestamp);
//         let exec_price = maker_order.price;
//         maker_order.match_price = median_price(
//             maker_order.match_price,
//             maker_order.filled_qty,
//             exec_price
//         );
//         maker_order.remain_qty = maker_order.remain_qty - exec_price;
//         maker_order.filled_qty = maker_order.filled_qty + exec_price;
//         update_order_state(maker_order, timestamp);
//         let bill = Bill {
//             taker_is_bid: false,
//             taker_ordid: taker_order.order_id,
//             maker_ordid: maker_order.order_id,
//             taker: taker_order.trader,
//             maker: maker_order.trader,
//             exec_price: maker_order.price,
//             exec_qty: exec_price,
//             timestamp,
//             nft: *option::borrow(&taker_order.nft_id),
//             maker_filled: maker_order.status == constants::filled(),
//         };
//         vector::push_back(bills, bill);
//         false
//     }

//     fun median_price(
//         a: u64,
//         b: u64,
//         c: u64
//     ): u64 {
//         if (a == 0) {
//             c
//         } else {
//             math::div(
//                 math::mul(b + c, a),
//                 b + a
//             )
//         }
//     }

//     fun order_mut(
//         book: &mut Book,
//         order_id: u128
//     ): &mut Order {
//         big_vector::borrow_mut<Order>(
//             book_side_mut(book, order_id),
//             order_id
//         )
//     }

//     fun setStatus(
//         order: &mut Order,
//         status: u8
//     ) {
//         order.status = status;
//         event::emit<OrderEvent>(make_event(order));
//     }

//     fun to_order(
//         order_id: u128,
//         order_info: &OrderInfo
//     ): Order {
//         Order {
//             market_id: order_info.market_id,
//             trader: order_info.trader,
//             order_id: order_id,
//             origin_qty: order_info.balance,
//             remain_qty: order_info.balance,
//             filled_qty: 0,
//             is_bid: order_info.is_bid,
//             nft_id: order_info.nft_id,
//             price: order_info.price,
//             match_price: 0,
//             ord_type: order_info.ord_type,
//             cross_id: order_info.cross_id,
//             status: constants::live(),
//             expire_timestamp: order_info.expire_timestamp,
//             fill_mode: order_info.fill_mode,
//         }
//     }

//     fun update_order_state(order: &mut Order, current_time: u64) {
//         if (order.status >= constants::expired()) {
//             return;
//         };
//         if (order_expired0(order, current_time)) {
//             setStatus(order, constants::expired());
//             return;
//         };
//         if (order.is_bid) {
//             if (order.ord_type == constants::ord_limit()) {
//                 if (order.filled_qty > 0) {
//                     let new_status = if (order.remain_qty < order.price) {
//                         constants::filled()
//                     } else {
//                         constants::partially_filled()
//                     };
//                     setStatus(order, new_status);
//                 };
//             } else {
//                 if (order.filled_qty > 0) {
//                     let new_status = if (order.remain_qty == 0) {
//                         constants::filled()
//                     } else {
//                         constants::partially_filled()
//                     };
//                     setStatus(order, new_status);
//                 };
//             };
//         } else {
//             if (order.filled_qty > 0) {
//                 setStatus(order, constants::filled());
//             };
//         };
//     }

//     fun validate_inputs(
//         order_info: &OrderInfo,
//         tick_size: u64,
//         min_balance: u64,
//         current_timestamp: u64
//     ) {
//         assert!(
//             order_info.fill_mode <= constants::ice_berge(),
//             8
//         );
//         assert!(
//             order_info.ord_type <= constants::ord_limit(),
//             12
//         );
//         assert!(order_info.balance > 0, 1);

//         let is_valid_fill_mode = if (order_info.is_bid && order_info.fill_mode == constants::ice_berge()) {
//             true
//         } else {
//             !order_info.is_bid && order_info.fill_mode == constants::atomic()
//         };
//         assert!(is_valid_fill_mode, 9);

//         if (order_info.fill_mode == constants::ice_berge()) {
//             assert!(order_info.balance >= min_balance, 5);
//         } else {
//             assert!(order_info.balance == 1, 5);
//             assert!(option::is_some<object::ID>(&order_info.nft_id), 16);
//         };

//         assert!(
//             order_info.expire_timestamp == 0 || current_timestamp < order_info.expire_timestamp,
//             11
//         );

//         let is_valid_price = if (order_info.ord_type < constants::ord_limit() && order_info.price == 0) {
//             true
//         } else {
//             order_info.ord_type == constants::ord_limit() &&
//             order_info.price >= constants::min_price() &&
//             order_info.price <= constants::max_price()
//         };
//         assert!(is_valid_price, 13);

//         assert!(order_info.price % tick_size == 0, 13);
//     }

//     public(package) fun cancel_order(
//         book: &mut Book,
//         order_id: u128
//     ): Order {
//         let order = big_vector::remove<Order>(
//             book_side_mut(book, order_id),
//             order_id
//         );
//         setStatus(&mut order, constants::canceled());
//         order
//     }

//     public(package) fun empty(
//         base_fee: u64,
//         tick_size: u64,
//         min_size: u64,
//         ctx: &mut tx_context::TxContext
//     ): Book {
//         Book {
//             base_fee,
//             tick_size,
//             min_size,
//             asks: big_vector::empty<Order>(
//                 constants::max_slice_size(),
//                 constants::max_fan_out(),
//                 ctx
//             ),
//             bids: big_vector::empty<Order>(
//                 constants::max_slice_size(),
//                 constants::max_fan_out(),
//                 ctx
//             ),
//             next_bid_order_id: 18446744073709551615,
//             next_ask_order_id: 1,
//         }
//     }

//     public(package) fun make_and_fire_event_filled(
//         market_id: object::ID,
//         bill: &Bill,
//         trading_fee: u64,
//         royalty_fee: u64
//     ) {
//         let filled_event = Filled {
//             market_id,
//             taker_is_bid: bill.taker_is_bid,
//             taker_ordid: bill.taker_ordid,
//             maker_ordid: bill.maker_ordid,
//             taker: bill.taker,
//             maker: bill.maker,
//             filled_value: bill.exec_qty,
//             filled_price: bill.exec_price,
//             trading_fee,
//             royalty_fee,
//             nft: bill.nft,
//             timestamp: bill.timestamp,
//         };
//         event::emit<Filled>(filled_event);
//     }

//     public(package) fun make_order_info(
//         market_id: object::ID,
//         trader: address,
//         balance: u64,
//         is_bid: bool,
//         nft_id: option::Option<object::ID>,
//         price: u64,
//         ord_type: u8,
//         cross_id: u128,
//         expire_timestamp: u64,
//         fill_mode: u8
//     ): OrderInfo {
//         OrderInfo {
//             market_id,
//             trader,
//             balance,
//             is_bid,
//             nft_id,
//             price,
//             ord_type,
//             cross_id,
//             fill_mode,
//             expire_timestamp,
//         }
//     }

//     public(package) fun min_size(book: &Book): u64 {
//         book.min_size
//     }

//     public(package) fun order(
//         book: &Book,
//         index: u128
//     ): &Order {
//         big_vector::borrow<Order>(
//             book_side(book, index),
//             index
//         )
//     }

//     public(package) fun order_expired(
//         book: &Book,
//         order_id: u128,
//         current_time: u64
//     ): bool {
//         order_expired0(
//             big_vector::borrow<Order>(
//                 book_side(book, order_id),
//                 order_id
//             ),
//             current_time
//         )
//     }

//     public(package) fun order_expired0(
//         order: &Order,
//         current_timestamp: u64
//     ): bool {
//         (order.expire_timestamp > 0) && (order.expire_timestamp <= current_timestamp)
//     }

//     public(package) fun order_info(
//         order: &Order
//     ): (bool, address, u64, option::Option<object::ID>, u64) {
//         (
//             order.is_bid,
//             order.trader,
//             order.remain_qty,
//             order.nft_id,
//             order.price
//         )
//     }

//     public(package) fun order_nft(
//         book: &Book,
//         order_id: u128
//     ): option::Option<object::ID> {
//         let order_result = order(book, order_id);
//         order_result.nft_id
//     }

//     public(package) fun place_cross(
//         book: &mut Book,
//         order_info: &OrderInfo,
//         is_taker_bid: bool,
//         timestamp: u64
//     ): (option::Option<Bill>, option::Option<ExpiredBill>, address, u64) {
//         let cross_id = order_info.cross_id;
//         let maker_order = order_mut(book, cross_id);

//         assert!(is_taker_bid || order_info.trader != maker_order.trader, 19);
//         assert!(
//             order_info.ord_type == constants::ord_cross()
//             && order_info.nft_id == maker_order.nft_id
//             && order_info.balance >= maker_order.price
//             && maker_order.remain_qty == 1,
//             18
//         );

//         let taker_order = to_order(
//             obutils::encode_order_id(
//                 order_info.is_bid,
//                 order_info.price,
//                 get_order_id(book, order_info.is_bid)
//             ),
//             order_info
//         );

//         setStatus(&mut taker_order, constants::live());

//         if (order_expired0(maker_order, timestamp)) {
//             setStatus(maker_order, constants::expired());

//             let expired_bill = ExpiredBill {
//                 maker_is_bid: !taker_order.is_bid,
//                 maker_order_id: maker_order.order_id,
//                 maker: maker_order.trader,
//                 exec_price: maker_order.price,
//                 exec_qty: maker_order.remain_qty,
//                 nft_id: maker_order.nft_id,
//             };

//             big_vector::remove<Order>(
//                 book_side_mut(book, cross_id),
//                 cross_id
//             );

//             (
//                 option::none<Bill>(),
//                 option::some<ExpiredBill>(expired_bill),
//                 taker_order.trader,
//                 taker_order.remain_qty
//             )
//         } else {
//             maker_order.remain_qty = 0;
//             maker_order.filled_qty = 1;
//             maker_order.match_price = maker_order.price;

//             setStatus(maker_order, constants::filled());

//             let exec_price = maker_order.price;

//             taker_order.match_price = median_price(
//                 taker_order.match_price,
//                 taker_order.filled_qty,
//                 exec_price
//             );

//             taker_order.remain_qty = taker_order.remain_qty - exec_price;
//             taker_order.filled_qty = taker_order.filled_qty + exec_price;

//             setStatus(&mut taker_order, constants::completed());

//             let bill = Bill {
//                 taker_is_bid: true,
//                 taker_ordid: taker_order.order_id,
//                 maker_ordid: maker_order.order_id,
//                 taker: taker_order.trader,
//                 maker: maker_order.trader,
//                 exec_price,
//                 exec_qty: exec_price,
//                 timestamp,
//                 nft: *option::borrow<object::ID>(&maker_order.nft_id),
//                 maker_filled: true,
//             };

//             big_vector::remove<Order>(
//                 book_side_mut(book, cross_id),
//                 cross_id
//             );

//             (
//                 option::some<Bill>(bill),
//                 option::none<ExpiredBill>(),
//                 taker_order.trader,
//                 taker_order.remain_qty
//             )
//         }
//     }

//     public(package) fun place_order(
//         book: &mut Book,
//         order_info: &OrderInfo,
//         is_post_only: bool,
//         max_qty: u64
//     ): TradeProof {
//         validate_inputs(order_info, book.tick_size, book.min_size, max_qty);
//         assert!(
//             order_info.ord_type <= constants::ord_limit(),
//             9
//         );

//         let order_id = obutils::encode_order_id(
//             order_info.is_bid,
//             order_info.price,
//             get_order_id(book, order_info.is_bid)
//         );

//         let order = to_order(order_id, order_info);

//         let trade_proof = TradeProof {
//             taker: order.trader,
//             fills: vector::empty<Bill>(),
//             delists: vector::empty<ExpiredBill>(),
//             fill_limit_reached: false,
//             order_id,
//             inject: false,
//             remain_qty: order.origin_qty,
//             taker_is_bid: order.is_bid,
//             taker_nft: order.nft_id,
//         };

//         setStatus(&mut order, constants::live());

//         match_against_book(book, &mut order, &mut trade_proof, is_post_only, max_qty);

//         trade_proof.inject = inject_taker_order(&order, &trade_proof);
//         trade_proof.remain_qty = order.remain_qty;

//         if (trade_proof.inject) {
//             inject_limit_order(book, order);
//         } else {
//             setStatus(&mut order, constants::completed());
//         };

//         trade_proof
//     }

//     public(package) fun tick_size(book: &Book): u64 {
//         book.tick_size
//     }

//     public fun bill_info(
//         trade_proof: &TradeProof
//     ): (&vector<Bill>, &vector<ExpiredBill>) {
//         (&trade_proof.fills, &trade_proof.delists)
//     }

//     public fun trade_info(
//         trade_proof: &TradeProof
//     ): (address, u128, bool, u64, bool, option::Option<object::ID>) {
//         (
//             trade_proof.taker,
//             trade_proof.order_id,
//             trade_proof.inject,
//             trade_proof.remain_qty,
//             trade_proof.taker_is_bid,
//             trade_proof.taker_nft
//         )
//     }

//     public fun order_id(trade_proof: &TradeProof): u128 {
//         trade_proof.order_id
//     }

//     public fun fill_info(
//         bill: &Bill
//     ): (bool, address, u64, u64, object::ID) {
//         (
//             bill.taker_is_bid,
//             bill.maker,
//             bill.exec_qty,
//             bill.exec_price,
//             bill.nft
//         )
//     }

//     public fun fill_maker(bill: &Bill): address {
//         bill.maker
//     }

//     public fun fill_taker(bill: &Bill): address {
//         bill.taker
//     }

//     public fun expired_info(
//         expired_bill: &ExpiredBill
//     ): (bool, address, u64, option::Option<object::ID>) {
//         (
//             expired_bill.maker_is_bid,
//             expired_bill.maker,
//             expired_bill.exec_qty,
//             expired_bill.nft_id
//         )
//     }

//     public fun confirm_proof(proof: TradeProof) {
//         let TradeProof {
//             taker: _,
//             fills: _,
//             delists: _,
//             fill_limit_reached: _,
//             order_id: _,
//             inject: _,
//             remain_qty: _,
//             taker_is_bid: _,
//             taker_nft: _,
//         } = proof;
//     }

//     public fun remain_balance(order: &Order): u64 {
//         order.remain_qty
//     }

//     public fun book_size(book: &Book): (u64, u64) {
//         let bid_size = big_vector::length<Order>(bids(book));
//         let ask_size = big_vector::length<Order>(asks(book));
//         (bid_size, ask_size)
//     }
// }