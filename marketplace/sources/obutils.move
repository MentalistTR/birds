// Decompiled by SuiGPT
module marketplace::obutils {

    // ----- Use Statements -----

    // ----- Functions -----

    public(package) fun decode_order_id(order_id: u128): (bool, u64, u64) {
        let is_buy = ((order_id >> 127) == 0);
        let price = (((order_id >> 64) as u64) & 9223372036854775807);
        let quantity = ((order_id & 18446744073709551615) as u64);
        (is_buy, price, quantity)
    }

    public(package) fun encode_order_id(
        is_buy: bool,
        price: u64,
        quantity: u64
    ): u128 {
        if (is_buy) {
            (((price as u128) << 64) + (quantity as u128))
        } else {
            (170141183460469231731687303715884105728 + ((price as u128) << 64) + (quantity as u128))
        }
    }

    public(package) fun pop_n<T>(
        vec: &mut vector<T>,
        n: u64
    ): vector<T> {
        let mut result = vector::empty<T>();
        let mut count = n;
        while (count > 0) {
            vector::push_back(&mut result, vector::pop_back(vec));
            count = count - 1;
        };
        vector::reverse(&mut result);
        result
    }

    public(package) fun pop_until<T>(
        vec: &mut vector<T>,
        target_length: u64
    ): vector<T> {
        let mut result = vector::empty<T>();
        while (vector::length(vec) > target_length) {
            vector::push_back(&mut result, vector::pop_back(vec));
        };
        vector::reverse(&mut result);
        result
    }

    public fun vec_toids(addresses: &vector<address>): vector<object::ID> {
        let mut ids = vector::empty<object::ID>();
        let mut index = vector::length<address>(addresses);
        while (index > 0) {
            let new_index = index - 1;
            index = new_index;
            let address = *vector::borrow<address>(addresses, new_index);
            let id = object::id_from_address(address);
            vector::push_back<object::ID>(&mut ids, id);
        };
        ids
    }
}