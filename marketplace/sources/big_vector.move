// Decompiled by SuiGPT
module marketplace::big_vector;

use marketplace::obutils;
use sui::dynamic_field;

// ----- Use Statements -----

// ----- Structs -----

public struct BigVector<phantom T0: store> has store, key {
    id: object::UID,
    depth: u8,
    length: u64,
    max_slice_size: u64,
    max_fan_out: u64,
    root_id: u64,
    last_id: u64,
}

public struct Slice<T0: store> has drop, store {
    prev: u64,
    next: u64,
    keys: vector<u128>,
    vals: vector<T0>,
}

public struct SliceRef has copy, drop, store {
    ix: u64,
}

// ----- Functions -----

fun alloc<T0: store, T1: store>(big_vector: &mut BigVector<T0>, slice: Slice<T1>): u64 {
    let prev_id = slice.prev;
    let next_id = slice.next;

    big_vector.last_id = big_vector.last_id + 1;
    dynamic_field::add<u64, Slice<T1>>(&mut big_vector.id, big_vector.last_id, slice);

    let new_id = big_vector.last_id;

    if (prev_id != 0) {
        let prev_slice = dynamic_field::borrow_mut<u64, Slice<T1>>(&mut big_vector.id, prev_id);
        prev_slice.next = new_id;
    };

    if (next_id != 0) {
        let next_slice = dynamic_field::borrow_mut<u64, Slice<T1>>(&mut big_vector.id, next_id);
        next_slice.prev = new_id;
    };

    new_id
}

fun branch(key: u128, value1: u64, value2: u64): Slice<u64> {
    let mut keys = vector::empty<u128>();
    vector::push_back(&mut keys, key);

    let mut values = vector::empty<u64>();
    vector::push_back(&mut values, value1);
    vector::push_back(&mut values, value2);

    Slice<u64> {
        prev: 0,
        next: 0,
        keys,
        vals: values,
    }
}

fun drop_slice<T: drop + store>(uid: &mut object::UID, depth: u8, key: u64) {
    if (key == 0) {
        return;
    };
    if (depth == 0) {
        dynamic_field::remove<u64, Slice<T>>(uid, key);
    } else {
        let mut slice = dynamic_field::remove<u64, Slice<u64>>(uid, key);
        while (!vector::is_empty(&slice.vals)) {
            let next_key = vector::pop_back(&mut slice.vals);
            drop_slice<T>(uid, depth - 1, next_key);
        };
    };
}

fun find_leaf<T: store>(big_vector: &BigVector<T>, target: u128): (u64, &Slice<T>, u64) {
    let mut depth = big_vector.depth;
    let mut current_id = big_vector.root_id;

    while (depth > 0) {
        let slice = dynamic_field::borrow<u64, Slice<u64>>(&big_vector.id, current_id);
        current_id = *vector::borrow(&slice.vals, slice_bisect_right<u64>(slice, target));
        depth = depth - 1;
    };

    let leaf_slice = dynamic_field::borrow<u64, Slice<T>>(&big_vector.id, current_id);
    (current_id, leaf_slice, slice_bisect_left<T>(leaf_slice, target))
}

fun find_max_leaf<T: store>(big_vector: &BigVector<T>): (u64, &Slice<T>, u64) {
    let mut depth = big_vector.depth;
    let mut current_id = big_vector.root_id;

    while (depth > 0) {
        let slice = dynamic_field::borrow<u64, Slice<u64>>(&big_vector.id, current_id);
        current_id =
            *vector::borrow<u64>(
                &slice.vals,
                vector::length<u128>(&slice.keys),
            );
        depth = depth - 1;
    };

    let max_leaf_slice = dynamic_field::borrow<u64, Slice<T>>(&big_vector.id, current_id);
    (current_id, max_leaf_slice, vector::length<u128>(&max_leaf_slice.keys) - 1)
}

fun find_min_leaf<T: store>(big_vector: &BigVector<T>): (u64, &Slice<T>, u64) {
    let mut depth = big_vector.depth;
    let mut current_id = big_vector.root_id;

    while (depth > 0) {
        let slice_u64 = dynamic_field::borrow<u64, Slice<u64>>(&big_vector.id, current_id);
        let first_val = vector::borrow<u64>(&slice_u64.vals, 0);
        current_id = *first_val;
        depth = depth - 1;
    };

    (current_id, dynamic_field::borrow<u64, Slice<T>>(&big_vector.id, current_id), 0)
}

fun leaf_insert<T: store>(
    big_vector: &mut BigVector<T>,
    slice_id: u64,
    key: u128,
    value: T,
): (u128, u64) {
    let slice = dynamic_field::borrow_mut<u64, Slice<T>>(&mut big_vector.id, slice_id);
    let position = slice_bisect_left(slice, key);

    if (position < vector::length(&slice.keys) && key == *vector::borrow(&slice.keys, position)) {
        abort 6;
    };

    if (vector::length(&slice.keys) < big_vector.max_slice_size) {
        vector::insert(&mut slice.keys, key, position);
        vector::insert(&mut slice.vals, value, position);
        return (0, 0);
    };

    let mid = vector::length(&slice.vals) / 2;
    let mut new_slice = Slice<T> {
        prev: slice_id,
        next: slice.next,
        keys: obutils::pop_until(&mut slice.keys, mid),
        vals: obutils::pop_until(&mut slice.vals, mid),
    };

    let first_key_in_new_slice = *vector::borrow(&new_slice.keys, 0);

    if (key < first_key_in_new_slice) {
        vector::insert(&mut slice.keys, key, position);
        vector::insert(&mut slice.vals, value, position);
    } else {
        vector::insert(&mut new_slice.keys, key, position - mid);
        vector::insert(&mut new_slice.vals, value, position - mid);
    };

    (first_key_in_new_slice, alloc(big_vector, new_slice))
}

fun leaf_remove<T: store>(
    big_vector: &mut BigVector<T>,
    left_slice_id: u64,
    left_slice_key: u128,
    current_slice_id: u64,
    current_slice_key: u128,
    right_slice_id: u64,
    right_slice_key: u128,
): (T, u8, u128) {
    // Step 1: Borrow the current slice mutably
    let (current_vals_length, half_max_slice_size, removed_value) = {
        let current_slice = dynamic_field::borrow_mut<u64, Slice<T>>(
            &mut big_vector.id,
            current_slice_id,
        );
        let index = slice_bisect_left<T>(current_slice, right_slice_key);

        if (index >= vector::length<u128>(&current_slice.keys)) {
            abort 5;
        };
        if (right_slice_key != *vector::borrow<u128>(&current_slice.keys, index)) {
            abort 5;
        };

        // Remove the key and value from the current slice
        vector::remove<u128>(&mut current_slice.keys, index);
        let removed_value = vector::remove<T>(&mut current_slice.vals, index);
        let current_vals_length = vector::length<T>(&current_slice.vals);
        let half_max_slice_size = big_vector.max_slice_size / 2;

        (current_vals_length, half_max_slice_size, removed_value)
    }; // Mutable borrow of `current_slice` ends here.

    // Step 2: Handle redistribution from the left slice
    if (left_slice_id != 0) {
        let left_slice_vals_length = {
            let left_slice = dynamic_field::borrow<u64, Slice<T>>(&big_vector.id, left_slice_id);
            vector::length<T>(&left_slice.vals)
        };

        if (left_slice_vals_length > half_max_slice_size) {
            return (
                removed_value,
                2,
                slice_redistribute<T, T>(
                    big_vector,
                    left_slice_id,
                    left_slice_key,
                    current_slice_id,
                ),
            );
        };
    };

    // Step 3: Handle redistribution from the right slice
    if (right_slice_id != 0) {
        let right_slice_vals_length = {
            let right_slice = dynamic_field::borrow<u64, Slice<T>>(&big_vector.id, right_slice_id);
            vector::length<T>(&right_slice.vals)
        };

        if (right_slice_vals_length > half_max_slice_size) {
            return (
                removed_value,
                3,
                slice_redistribute<T, T>(
                    big_vector,
                    current_slice_id,
                    current_slice_key,
                    right_slice_id,
                ),
            );
        };
    };

    // Step 4: Merge slices if redistribution is not possible
    if (left_slice_id != 0) {
        slice_merge<T, T>(big_vector, left_slice_id, left_slice_key, current_slice_id);
        return (removed_value, 4, 0);
    };

    if (right_slice_id != 0) {
        slice_merge<T, T>(big_vector, current_slice_id, current_slice_key, right_slice_id);
        return (removed_value, 5, 0);
    };

    // Step 5: Handle the case where the current slice is empty
    let (status, redistribution_key) = if (current_vals_length == 0) {
        (1, 0)
    } else {
        (0, 0)
    };

    (removed_value, status, redistribution_key)
}

fun node_insert<T: store>(
    big_vector: &mut BigVector<T>,
    slice_id: u64,
    depth: u8,
    key: u128,
    value: T,
): (u128, u64) {
    let slice = dynamic_field::borrow_mut<u64, Slice<u64>>(&mut big_vector.id, slice_id);
    let insert_index = slice_bisect_right<u64>(slice, key);
    let (new_key, new_value) = slice_insert<T>(
        big_vector,
        *vector::borrow<u64>(&slice.vals, insert_index),
        depth,
        key,
        value,
    );

    if (new_value == 0) {
        return (0, 0);
    };

    let updated_slice = dynamic_field::borrow_mut<u64, Slice<u64>>(&mut big_vector.id, slice_id);

    if (vector::length<u64>(&updated_slice.vals) < big_vector.max_fan_out) {
        vector::insert<u128>(&mut updated_slice.keys, new_key, insert_index);
        vector::insert<u64>(&mut updated_slice.vals, new_value, insert_index + 1);
        return (0, 0);
    };

    let mut mid_index = vector::length<u64>(&updated_slice.vals) / 2;
    let mut new_slice = Slice<u64> {
        prev: slice_id,
        next: updated_slice.next,
        keys: obutils::pop_until<u128>(&mut updated_slice.keys, mid_index),
        vals: obutils::pop_until<u64>(&mut updated_slice.vals, mid_index),
    };

    let split_key = vector::pop_back<u128>(&mut updated_slice.keys);

    if (new_key < split_key) {
        vector::insert<u128>(&mut updated_slice.keys, new_key, insert_index);
        vector::insert<u64>(&mut updated_slice.vals, new_value, insert_index + 1);
    } else {
        vector::insert<u128>(&mut new_slice.keys, new_key, insert_index - mid_index);
        vector::insert<u64>(&mut new_slice.vals, new_value, insert_index - mid_index + 1);
    };

    (split_key, alloc<T, u64>(big_vector, new_slice))
}

fun node_remove<T: store>(
    big_vector: &mut BigVector<T>,
    left_slice_id: u64,
    left_key: u128,
    current_slice_id: u64,
    current_key: u128,
    right_slice_id: u64,
    remove_type: u8,
    remove_key: u128,
): (T, u8, u128) {
    let current_slice = dynamic_field::borrow<u64, Slice<u64>>(&big_vector.id, current_slice_id);
    let bisect_index = slice_bisect_right<u64>(current_slice, remove_key);

    let (left_val, left_key) = if (bisect_index == 0) {
        (0, 0)
    } else {
        (
            *vector::borrow<u64>(&current_slice.vals, bisect_index - 1),
            *vector::borrow<u128>(&current_slice.keys, bisect_index - 1),
        )
    };

    let (right_val, right_key) = if (bisect_index == vector::length<u128>(&current_slice.keys)) {
        (0, 0)
    } else {
        (
            *vector::borrow<u64>(&current_slice.vals, bisect_index + 1),
            *vector::borrow<u128>(&current_slice.keys, bisect_index),
        )
    };

    let (removed_value, result_type, new_key) = slice_remove<T>(
        big_vector,
        left_val,
        left_key,
        *vector::borrow<u64>(&current_slice.vals, bisect_index),
        right_key,
        right_val,
        remove_type,
        remove_key,
    );

    let current_slice_mut = dynamic_field::borrow_mut<u64, Slice<u64>>(
        &mut big_vector.id,
        current_slice_id,
    );

    if (result_type == 0) {
        return (removed_value, 0, 0);
    };

    if (result_type == 2) {
        *vector::borrow_mut<u128>(&mut current_slice_mut.keys, bisect_index - 1) = new_key;
        return (removed_value, 0, 0);
    };

    if (result_type == 3) {
        *vector::borrow_mut<u128>(&mut current_slice_mut.keys, bisect_index) = new_key;
        return (removed_value, 0, 0);
    };

    if (result_type == 4) {
        vector::remove<u128>(&mut current_slice_mut.keys, bisect_index - 1);
        vector::remove<u64>(&mut current_slice_mut.vals, bisect_index);
    } else {
        assert!(result_type == 5, 7);
        vector::remove<u128>(&mut current_slice_mut.keys, bisect_index);
        vector::remove<u64>(&mut current_slice_mut.vals, bisect_index + 1);
    };

    let current_length = vector::length<u64>(&current_slice_mut.vals);
    let min_fan_out = big_vector.max_fan_out / 2;

    if (current_length >= min_fan_out) {
        return (removed_value, 0, 0);
    };

    if (left_slice_id != 0) {
        let left_slice = dynamic_field::borrow<u64, Slice<u64>>(&big_vector.id, left_slice_id);
        if (vector::length<u64>(&left_slice.vals) > min_fan_out) {
            return (
                removed_value,
                2,
                slice_redistribute<T, u64>(big_vector, left_slice_id, left_key, current_slice_id),
            );
        };
    };

    if (right_slice_id != 0) {
        let right_slice = dynamic_field::borrow<u64, Slice<u64>>(&big_vector.id, right_slice_id);
        if (vector::length<u64>(&right_slice.vals) > min_fan_out) {
            return (
                removed_value,
                3,
                slice_redistribute<T, u64>(
                    big_vector,
                    current_slice_id,
                    current_key,
                    right_slice_id,
                ),
            );
        };
    };

    if (left_slice_id != 0) {
        slice_merge<T, u64>(big_vector, left_slice_id, left_key, current_slice_id);
        return (removed_value, 4, 0);
    };

    if (right_slice_id != 0) {
        slice_merge<T, u64>(big_vector, current_slice_id, current_key, right_slice_id);
        return (removed_value, 5, 0);
    };

    if (current_length == 0) {
        abort 7;
    };

    let (result_type_final, new_key_final) = if (current_length == 1) {
        (1, 0)
    } else {
        (0, 0)
    };

    (removed_value, result_type_final, new_key_final)
}

fun singleton<T: store>(key: u128, value: T): Slice<T> {
    let mut keys = vector::empty<u128>();
    vector::push_back(&mut keys, key);
    let mut values = vector::empty<T>();
    vector::push_back(&mut values, value);
    Slice<T> {
        prev: 0,
        next: 0,
        keys,
        vals: values,
    }
}

fun slice_bisect_left<T: store>(slice: &Slice<T>, key: u128): u64 {
    let mut high = vector::length<u128>(&slice.keys);
    let mut low = 0;
    while (low < high) {
        let mid = (high - low) / 2 + low;
        if (key <= *vector::borrow<u128>(&slice.keys, mid)) {
            high = mid;
            continue;
        };
        low = mid + 1;
    };
    low
}

fun slice_bisect_right<T: store>(slice: &Slice<T>, key: u128): u64 {
    let mut high = vector::length(&slice.keys);
    let mut low = 0;
    while (low < high) {
        let mid = ((high - low) / 2) + low;
        if (key < *vector::borrow(&slice.keys, mid)) {
            high = mid;
            continue;
        };
        low = mid + 1;
    };
    low
}

fun slice_insert<T: store>(
    big_vector: &mut BigVector<T>,
    index: u64,
    depth: u8,
    offset: u128,
    value: T,
): (u128, u64) {
    if (depth == 0) {
        let (leaf_offset, leaf_index) = leaf_insert(big_vector, index, offset, value);
        (leaf_offset, leaf_index)
    } else {
        let (node_offset, node_index) = node_insert(big_vector, index, depth - 1, offset, value);
        (node_offset, node_index)
    }
}

fun slice_merge<T0: store, T1: store>(
    big_vector: &mut BigVector<T0>,
    slice_id: u64,
    key: u128,
    next_slice_id: u64,
) {
    let removed_slice = dynamic_field::remove<u64, Slice<T1>>(&mut big_vector.id, next_slice_id);
    let current_slice = dynamic_field::borrow_mut<u64, Slice<T1>>(&mut big_vector.id, slice_id);

    assert!(current_slice.next == next_slice_id, 8);
    assert!(removed_slice.prev == slice_id, 8);

    if (!slice_is_leaf<T1>(current_slice)) {
        vector::push_back<u128>(&mut current_slice.keys, key);
    };

    let Slice {
        prev: _,
        next: next_id,
        keys: removed_keys,
        vals: removed_vals,
    } = removed_slice;

    vector::append<u128>(&mut current_slice.keys, removed_keys);
    vector::append<T1>(&mut current_slice.vals, removed_vals);

    current_slice.next = next_id;

    if (next_id != 0) {
        let next_slice = dynamic_field::borrow_mut<u64, Slice<T1>>(&mut big_vector.id, next_id);
        next_slice.prev = slice_id;
    };
}

fun slice_redistribute<T0: store, T1: store>(
    big_vector: &mut BigVector<T0>,
    slice_id1: u64,
    key: u128,
    slice_id2: u64,
): u128 {
    // Remove slices from the big vector
    let slice1 = dynamic_field::remove<u64, Slice<T1>>(&mut big_vector.id, slice_id1);
    let slice2 = dynamic_field::remove<u64, Slice<T1>>(&mut big_vector.id, slice_id2);

    // Validate slice connections
    assert!(slice1.next == slice_id2, 8);
    assert!(slice2.prev == slice_id1, 8);

    let is_leaf = slice_is_leaf<T1>(&slice1);

    // Destructure slices
    let Slice {
        prev: prev1,
        next: next1,
        keys: mut keys1,
        vals: mut vals1,
    } = slice1;

    let Slice {
        prev: prev2,
        next: next2,
        keys: mut keys2,
        vals: mut vals2,
    } = slice2;

    // Calculate redistribution parameters
    let len1 = vector::length(&vals1);
    let len2 = vector::length(&vals2);
    let total_len = len1 + len2;
    let half_len = total_len / 2;
    let remaining_len = total_len - half_len;

    let redistribute_to_first = if (half_len < len1) {
        true
    } else {
        assert!(remaining_len < len2, 9);
        false
    };

    // Redistribute values
    let (new_vals1, new_vals2) = if (redistribute_to_first) {
        let mut popped_vals = obutils::pop_until(&mut vals1, half_len);
        vector::append(&mut popped_vals, vals2);
        (vals1, popped_vals)
    } else {
        vector::append(&mut vals1, vals2);
        let popped_vals = obutils::pop_n(&mut vals1, remaining_len);
        (vals1, popped_vals)
    };

    // Redistribute keys and calculate the new key
    let (new_keys1, new_key, new_keys2) = if (is_leaf && redistribute_to_first) {
        let mut popped_keys = obutils::pop_until(&mut keys1, half_len);
        vector::append(&mut popped_keys, keys2);
        let new_key = *vector::borrow(&popped_keys, 0);
        (keys1, new_key, popped_keys)
    } else if (is_leaf && !redistribute_to_first) {
        vector::append(&mut keys1, keys2);
        let popped_keys = obutils::pop_n(&mut keys1, remaining_len);
        let new_key = *vector::borrow(&popped_keys, 0);
        (keys1, new_key, popped_keys)
    } else if (!is_leaf && redistribute_to_first) {
        let mut popped_keys = obutils::pop_until(&mut keys1, half_len);
        vector::push_back(&mut popped_keys, key);
        vector::append(&mut popped_keys, keys2);
        let new_key = vector::pop_back(&mut keys1);
        (keys1, new_key, popped_keys)
    } else {
        vector::push_back(&mut keys1, key);
        vector::append(&mut keys1, keys2);
        let popped_keys = obutils::pop_n(&mut keys1, remaining_len - 1);
        let new_key = vector::pop_back(&mut keys1);
        (keys1, new_key, popped_keys)
    };

    // Construct new slices and update the big vector
    let new_slice1 = Slice<T1> {
        prev: prev1,
        next: next1,
        keys: new_keys1,
        vals: new_vals1,
    };
    dynamic_field::add(&mut big_vector.id, slice_id1, new_slice1);

    let new_slice2 = Slice<T1> {
        prev: prev2,
        next: next2,
        keys: new_keys2,
        vals: new_vals2,
    };
    dynamic_field::add(&mut big_vector.id, slice_id2, new_slice2);

    // Return the new key
    new_key
}

fun slice_remove<T: store>(
    big_vector: &mut BigVector<T>,
    index: u64,
    offset: u128,
    length: u64,
    total_size: u128,
    capacity: u64,
    depth: u8,
    position: u128,
): (T, u8, u128) {
    if (depth == 0) {
        let (value, new_depth, new_position) = leaf_remove(
            big_vector,
            index,
            offset,
            length,
            total_size,
            capacity,
            position,
        );
        (value, new_depth, new_position)
    } else {
        let (value, new_depth, new_position) = node_remove(
            big_vector,
            index,
            offset,
            length,
            total_size,
            capacity,
            depth - 1,
            position,
        );
        (value, new_depth, new_position)
    }
}

public fun empty<T: store>(
    max_slice_size: u64,
    max_fan_out: u64,
    ctx: &mut tx_context::TxContext,
): BigVector<T> {
    assert!(2 <= max_slice_size, 0);
    assert!(max_slice_size <= 262144, 1);
    assert!(4 <= max_fan_out, 2);
    assert!(max_fan_out <= 4096, 3);
    BigVector<T> {
        id: object::new(ctx),
        depth: 0,
        length: 0,
        max_slice_size,
        max_fan_out,
        root_id: 0,
        last_id: 0,
    }
}

public fun destroy_empty<T: store>(big_vector: BigVector<T>) {
    let BigVector {
        id,
        depth: _,
        length,
        max_slice_size: _,
        max_fan_out: _,
        root_id: _,
        last_id: _,
    } = big_vector;

    assert!(length == 0, 4);
    object::delete(id);
}

public fun is_empty<T: store>(big_vector: &BigVector<T>): bool {
    big_vector.length == 0
}

public fun length<T: store>(big_vector: &BigVector<T>): u64 {
    big_vector.length
}

public fun depth<T: store>(big_vector: &BigVector<T>): u8 {
    big_vector.depth
}

public fun borrow<T: store>(big_vector: &BigVector<T>, index: u128): &T {
    let (slice_index, element_index) = slice_around(big_vector, index);
    slice_borrow(
        borrow_slice(big_vector, slice_index),
        element_index,
    )
}

public fun borrow_mut<T: store>(big_vector: &mut BigVector<T>, index: u128): &mut T {
    let (slice_index, element_index) = slice_around(big_vector, index);
    slice_borrow_mut(
        borrow_slice_mut(big_vector, slice_index),
        element_index,
    )
}

public fun insert<T: store>(big_vector: &mut BigVector<T>, index: u128, value: T) {
    big_vector.length = big_vector.length + 1;
    if (big_vector.root_id == 0) {
        big_vector.root_id =
            alloc<T, T>(
                big_vector,
                singleton(index, value),
            );
        return;
    };

    let current_root_id = big_vector.root_id;
    let depth = big_vector.depth;

    let (new_root, new_branch) = slice_insert(
        big_vector,
        current_root_id,
        depth,
        index,
        value,
    );

    if (new_branch != 0) {
        big_vector.root_id =
            alloc<T, u64>(
                big_vector,
                branch(new_root, current_root_id, new_branch),
            );
        big_vector.depth = big_vector.depth + 1;
    };
}

public fun remove<T: store>(big_vector: &mut BigVector<T>, index: u128): T {
    if (big_vector.root_id == 0) {
        abort 5;
    };

    big_vector.length = big_vector.length - 1;
    let root_id = big_vector.root_id;
    let depth = big_vector.depth;
    // Call slice_remove to remove the specified index
    let (removed_value, slice_status, _) = slice_remove<T>(
        big_vector,
        0, // left_slice_id
        0, // left_slice_key
        root_id,
        0, // current_slice_key
        0, // right_slice_id
        depth,
        index,
    );

    // Handle slice_status and update the root_id if necessary
    if (slice_status == 1) {
        if (big_vector.depth == 0) {
            let Slice {
                prev: _,
                next: _,
                keys: _,
                vals: slice_values,
            } = dynamic_field::remove<u64, Slice<T>>(&mut big_vector.id, root_id);
            vector::destroy_empty(slice_values);
            big_vector.root_id = 0;
        } else {
            // Correctly reference 'mutslice' instead of 'slice'
            let mut mutslice = dynamic_field::remove<u64, Slice<u64>>(&mut big_vector.id, root_id);
            big_vector.root_id = vector::pop_back(&mut mutslice.vals); // Use 'mutslice' here
            big_vector.depth = big_vector.depth - 1;
        };
    };

    removed_value
}

public(package) fun remove_batch<T: store>(
    big_vector: &mut BigVector<T>,
    indices: vector<u128>,
): vector<T> {
    abort 0
}

public(package) fun slice_around<T: store>(big_vector: &BigVector<T>, key: u128): (SliceRef, u64) {
    if (big_vector.root_id == 0) {
        abort 5;
    };

    let (slice_index, leaf, position) = find_leaf<T>(big_vector, key);

    if (position >= vector::length<u128>(&leaf.keys)) {
        abort 5;
    };

    if (key != *vector::borrow<u128>(&leaf.keys, position)) {
        abort 5;
    };

    let slice_ref = SliceRef { ix: slice_index };
    (slice_ref, position)
}

public(package) fun slice_before<T: store>(big_vector: &BigVector<T>, key: u128): (SliceRef, u64) {
    if (big_vector.root_id == 0) {
        let slice_ref = SliceRef { ix: 0 };
        return (slice_ref, 0);
    };

    let (slice_index, slice_ref, position) = find_leaf<T>(big_vector, key);

    if (position == 0) {
        let prev_slice = slice_prev<T>(slice_ref);
        let (result_slice, result_position) = if (slice_is_null(&prev_slice)) {
            let null_slice = SliceRef { ix: 0 };
            (null_slice, 0)
        } else {
            let prev_keys = borrow_slice<T>(big_vector, prev_slice).keys;
            (prev_slice, vector::length(&prev_keys) - 1)
        };
        (result_slice, result_position)
    } else {
        let current_slice = SliceRef { ix: slice_index };
        (current_slice, position - 1)
    }
}

public(package) fun slice_borrow<T: store>(slice: &Slice<T>, index: u64): &T {
    vector::borrow(&slice.vals, index)
}

public(package) fun slice_is_leaf<T: store>(slice: &Slice<T>): bool {
    vector::length(&slice.vals) == vector::length<u128>(&slice.keys)
}

public(package) fun slice_length<T: store>(slice: &Slice<T>): u64 {
    vector::length(&slice.vals)
}

public(package) fun slice_next<T: store>(slice: &Slice<T>): SliceRef {
    SliceRef { ix: slice.next }
}

public(package) fun slice_prev<T: store>(slice: &Slice<T>): SliceRef {
    SliceRef { ix: slice.prev }
}

public fun slice_following<T: store>(big_vector: &BigVector<T>, key: u128): (SliceRef, u64) {
    if (big_vector.root_id == 0) {
        let slice_ref = SliceRef { ix: 0 };
        return (slice_ref, 0);
    };

    let (leaf_index, leaf, key_index) = find_leaf<T>(big_vector, key);

    if (key_index >= vector::length<u128>(&leaf.keys)) {
        let next_slice = slice_next<T>(leaf);
        (next_slice, 0)
    } else {
        let slice_ref = SliceRef { ix: leaf_index };
        (slice_ref, key_index)
    }
}

public fun min_slice<T: store>(big_vector: &BigVector<T>): (SliceRef, u64) {
    if (big_vector.root_id == 0) {
        let slice_ref = SliceRef { ix: 0 };
        return (slice_ref, 0);
    };
    let (min_index, _, min_value) = find_min_leaf<T>(big_vector);
    let slice_ref = SliceRef { ix: min_index };
    (slice_ref, min_value)
}

public fun max_slice<T: store>(big_vector: &BigVector<T>): (SliceRef, u64) {
    if (big_vector.root_id == 0) {
        let slice_ref = SliceRef { ix: 0 };
        return (slice_ref, 0);
    };
    let (max_leaf_index, _, max_value) = find_max_leaf<T>(big_vector);
    let slice_ref = SliceRef { ix: max_leaf_index };
    (slice_ref, max_value)
}

public fun next_slice<T: store>(
    big_vector: &BigVector<T>,
    slice_ref: SliceRef,
    index: u64,
): (SliceRef, u64) {
    let slice = borrow_slice<T>(big_vector, slice_ref);
    if (index + 1 < vector::length(&slice.vals)) {
        (slice_ref, index + 1)
    } else {
        (slice_next<T>(slice), 0)
    }
}

public fun prev_slice<T: store>(
    big_vector: &BigVector<T>,
    slice_ref: SliceRef,
    index: u64,
): (SliceRef, u64) {
    if (index > 0) {
        (slice_ref, index - 1)
    } else {
        let mut new_index = 0;
        let prev_slice_ref = slice_prev(borrow_slice(big_vector, slice_ref));
        if (!slice_is_null(&prev_slice_ref)) {
            new_index = vector::length(&borrow_slice(big_vector, prev_slice_ref).vals) - 1;
        };
        (prev_slice_ref, new_index)
    }
}

public fun borrow_slice<T: store>(big_vector: &BigVector<T>, slice_ref: SliceRef): &Slice<T> {
    dynamic_field::borrow<u64, Slice<T>>(&big_vector.id, slice_ref.ix)
}

public fun borrow_slice_mut<T: store>(
    big_vector: &mut BigVector<T>,
    slice_ref: SliceRef,
): &mut Slice<T> {
    dynamic_field::borrow_mut<u64, Slice<T>>(&mut big_vector.id, slice_ref.ix)
}

public fun slice_is_null(slice_ref: &SliceRef): bool {
    slice_ref.ix == 0
}

public fun slice_key<T: store>(slice: &Slice<T>, index: u64): u128 {
    *vector::borrow<u128>(&slice.keys, index)
}

public fun slice_borrow_mut<T: store>(slice: &mut Slice<T>, index: u64): &mut T {
    vector::borrow_mut(&mut slice.vals, index)
}
