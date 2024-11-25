// // Decompiled by SuiGPT
// module 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::public_kiosk {

//     // ----- Use Statements -----

//     use sui::object;
//     use std::type_name;
//     use sui::kiosk;
//     use sui::tx_context;
//     use sui::dynamic_field;
//     use 0x97bd3876f24d934fa2f2b61673674eed9e8b0ae19f3ad148970e562e7a83703f::version;
//     use sui::transfer_policy;
//     use sui::coin;
//     use sui::sui;
//     use sui::transfer;

//     // ----- Structs -----

//     struct KOrder has drop, store {
//         order_id: u128,
//         nft_id: object::ID,
//         owner: address,
//         ord_price: u64,
//         ord_state: u8,
//     }

//     struct PUBLIC_KIOSK has drop {
//         dummy_field: bool,
//     }

//     struct Pair has copy, drop, store {
//         nft: type_name::TypeName,
//         token: type_name::TypeName,
//     }

//     struct PairKey has copy, drop, store {
//         dummy_field: bool,
//     }

//     struct PublicKiosk has store {
//         kiosk: kiosk::Kiosk,
//         ownerCap: kiosk::KioskOwnerCap,
//     }

//     // ----- Functions -----

//     fun deleteOrder(order: KOrder): u128 {
//         let KOrder {
//             order_id,
//             nft_id: _,
//             owner: _,
//             ord_price: _,
//             ord_state: _,
//         } = order;
//         order_id
//     }

//     fun getPair<T0: store + key, T1>(): Pair {
//         Pair {
//             nft: type_name::get<T0>(),
//             token: type_name::get<T1>(),
//         }
//     }

//     fun init(
//         kiosk: PUBLIC_KIOSK,
//         ctx: &mut tx_context::TxContext
//     ) {
//     }

//     fun validatePair<T0: store + key, T1>(
//         kiosk: &mut PublicKiosk
//     ) {
//         let pair_key = PairKey { dummy_field: false };
//         let pair = dynamic_field::borrow<PairKey, Pair>(
//             kiosk::uid_mut_as_owner(&mut kiosk.kiosk, &kiosk.ownerCap),
//             pair_key
//         );
//         assert!(*pair == getPair<T0, T1>(), 3002);
//     }

//     public(package) fun bindOrderId(
//         kiosk: &mut PublicKiosk,
//         order_id: object::ID,
//         new_order_id: u128
//     ) {
//         let order = dynamic_field::borrow_mut<object::ID, KOrder>(
//             kiosk::uid_mut_as_owner(&mut kiosk.kiosk, &kiosk.ownerCap),
//             order_id
//         );
//         order.order_id = new_order_id;
//     }

//     public(package) fun createPublicKiosk<T0: store + key, T1>(
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ): PublicKiosk {
//         version::checkVersion(version, 1);
//         let (kiosk, owner_cap) = kiosk::new(ctx);
//         let pair_key = PairKey { dummy_field: false };
//         dynamic_field::add<PairKey, Pair>(
//             kiosk::uid_mut_as_owner(&mut kiosk, &owner_cap),
//             pair_key,
//             getPair<T0, T1>()
//         );
//         PublicKiosk {
//             kiosk,
//             ownerCap: owner_cap,
//         }
//     }

//     public(package) fun delist<T0: store + key, T1>(
//         public_kiosk: &mut PublicKiosk,
//         object_id: object::ID,
//         version: &version::Version,
//         ctx: &tx_context::TxContext
//     ) {
//         version::checkVersion(version, 1);
//         validatePair<T0, T1>(public_kiosk);
//         kiosk::delist<T0>(&mut public_kiosk.kiosk, &public_kiosk.ownerCap, object_id);
//         let order = dynamic_field::borrow_mut<object::ID, KOrder>(
//             kiosk::uid_mut_as_owner(&mut public_kiosk.kiosk, &public_kiosk.ownerCap),
//             object_id
//         );
//         assert!(order.owner == tx_context::sender(ctx), 3001);
//         order.ord_state = 0;
//     }

//     public(package) fun delistAndTake<T0: store + key, T1>(
//         kiosk: &mut PublicKiosk,
//         object_id: object::ID,
//         version: &version::Version,
//         ctx: &tx_context::TxContext
//     ): u128 {
//         version::checkVersion(version, 1);
//         delist<T0, T1>(kiosk, object_id, version, ctx);
//         take<T0, T1>(kiosk, object_id, version, ctx)
//     }

//     public(package) fun list<T0: store + key, T1>(
//         public_kiosk: &mut PublicKiosk,
//         object_id: object::ID,
//         price: u64,
//         version: &version::Version,
//         ctx: &tx_context::TxContext
//     ) {
//         version::checkVersion(version, 1);
//         validatePair<T0, T1>(public_kiosk);
//         kiosk::list<T0>(&mut public_kiosk.kiosk, &public_kiosk.ownerCap, object_id, 0);
//         let order = dynamic_field::borrow_mut<object::ID, KOrder>(
//             kiosk::uid_mut_as_owner(&mut public_kiosk.kiosk, &public_kiosk.ownerCap),
//             object_id
//         );
//         assert!(order.owner == tx_context::sender(ctx), 3001);
//         order.ord_price = price;
//         order.ord_state = 1;
//     }

//     public(package) fun orderId(order: &KOrder): u128 {
//         order.order_id
//     }

//     public(package) fun orderIdFromNft(
//         kiosk: &mut PublicKiosk,
//         nft_id: object::ID
//     ): u128 {
//         let k_order = dynamic_field::borrow_mut<object::ID, KOrder>(
//             kiosk::uid_mut_as_owner(&mut kiosk.kiosk, &kiosk.ownerCap),
//             nft_id
//         );
//         k_order.order_id
//     }

//     public(package) fun orderInfo(
//         order: &KOrder
//     ): (u128, object::ID, address, u64) {
//         (order.order_id, order.nft_id, order.owner, order.ord_price)
//     }

//     public(package) fun orderOwner(
//         kiosk: &mut PublicKiosk,
//         order_id: object::ID
//     ): address {
//         let order = dynamic_field::borrow_mut<object::ID, KOrder>(
//             kiosk::uid_mut_as_owner(&mut kiosk.kiosk, &kiosk.ownerCap),
//             order_id
//         );
//         order.owner
//     }

//     public(package) fun orderPrice(
//         kiosk: &mut PublicKiosk,
//         order_id: object::ID
//     ): u64 {
//         let order = dynamic_field::borrow_mut<object::ID, KOrder>(
//             kiosk::uid_mut_as_owner(&mut kiosk.kiosk, &kiosk.ownerCap),
//             order_id
//         );
//         assert!(order.ord_state >= 1, 3003);
//         order.ord_price
//     }

//     public(package) fun place<T0: store + key, T1>(
//         public_kiosk: &mut PublicKiosk,
//         nft: T0,
//         version: &version::Version,
//         ctx: &tx_context::TxContext
//     ) {
//         version::checkVersion(version, 1);
//         validatePair<T0, T1>(public_kiosk);
//         let nft_id = object::id(&nft);
//         kiosk::place(&mut public_kiosk.kiosk, &public_kiosk.ownerCap, nft);
//         let order = KOrder {
//             order_id: 0,
//             nft_id,
//             owner: tx_context::sender(ctx),
//             ord_price: 0,
//             ord_state: 0,
//         };
//         dynamic_field::add(
//             kiosk::uid_mut_as_owner(&mut public_kiosk.kiosk, &public_kiosk.ownerCap),
//             nft_id,
//             order
//         );
//     }

//     public(package) fun placeAndList<T0: store + key, T1>(
//         kiosk: &mut PublicKiosk,
//         item: T0,
//         price: u64,
//         version: &version::Version,
//         ctx: &tx_context::TxContext
//     ) {
//         version::checkVersion(version, 1);
//         place<T0, T1>(kiosk, item, version, ctx);
//         list<T0, T1>(kiosk, object::id(&item), price, version, ctx);
//     }

//     public(package) fun purchase<T0: store + key, T1>(
//         public_kiosk: &mut PublicKiosk,
//         object_id: object::ID,
//         version: &version::Version,
//         ctx: &mut tx_context::TxContext
//     ): (T0, transfer_policy::TransferRequest<T0>, KOrder) {
//         version::checkVersion(version, 1);
//         validatePair<T0, T1>(public_kiosk);
//         tx_context::sender(ctx);
//         let (item, transfer_request) = kiosk::purchase<T0>(
//             &mut public_kiosk.kiosk,
//             object_id,
//             coin::zero<sui::SUI>(ctx)
//         );
//         let order = dynamic_field::remove<object::ID, KOrder>(
//             kiosk::uid_mut_as_owner(&mut public_kiosk.kiosk, &public_kiosk.ownerCap),
//             object_id
//         );
//         (item, transfer_request, order)
//     }

//     public(package) fun take<T0: store + key, T1>(
//         kiosk: &mut PublicKiosk,
//         order_id: object::ID,
//         version: &version::Version,
//         ctx: &tx_context::TxContext
//     ): u128 {
//         version::checkVersion(version, 1);
//         validatePair<T0, T1>(kiosk);
//         let order = dynamic_field::remove<object::ID, KOrder>(
//             kiosk::uid_mut_as_owner(&mut kiosk.kiosk, &kiosk.ownerCap),
//             order_id
//         );
//         assert!(order.owner == tx_context::sender(ctx), 3001);
//         transfer::public_transfer(
//             kiosk::take<T0>(&mut kiosk.kiosk, &kiosk.ownerCap, order_id),
//             order.owner
//         );
//         deleteOrder(order)
//     }

//     public(package) fun updatePrice<T0: store + key, T1>(
//         kiosk: &mut PublicKiosk,
//         order_id: object::ID,
//         new_price: u64,
//         version: &version::Version,
//         ctx: &tx_context::TxContext
//     ) {
//         version::checkVersion(version, 1);
//         validatePair<T0, T1>(kiosk);
//         let order = dynamic_field::borrow_mut<object::ID, KOrder>(
//             kiosk::uid_mut_as_owner(&mut kiosk.kiosk, &kiosk.ownerCap),
//             order_id
//         );
//         assert!(order.owner == tx_context::sender(ctx), 3001);
//         assert!(order.ord_state == 1, 3003);
//         order.ord_price = new_price;
//     }
// }