// Decompiled by SuiGPT
module marketplace::math {

    // ----- Use Statements -----

    use std::vector;
    use std::u128;

    // ----- Functions -----

    fun div_internal(
        numerator: u64,
        denominator: u64
    ): (u64, u64) {
        let numerator_u128 = (numerator as u128);
        let denominator_u128 = (denominator as u128);
        let remainder_flag = if (numerator_u128 * 1000000000 % denominator_u128 == 0) {
            0
        } else {
            1
        };
        (remainder_flag, ((numerator_u128 * 1000000000 / denominator_u128) as u64))
    }

    fun div_internal_u128(
        numerator: u128,
        denominator: u128
    ): (u128, u128) {
        let numerator_u256 = (numerator as u256);
        let denominator_u256 = (denominator as u256);
        let remainder_flag = if (numerator_u256 * 1000000000 % denominator_u256 == 0) {
            0
        } else {
            1
        };
        (remainder_flag, ((numerator_u256 * 1000000000 / denominator_u256) as u128))
    }

    fun mul_internal(
        a: u64,
        b: u64
    ): (u64, u64) {
        let a_u128 = (a as u128);
        let b_u128 = (b as u128);
        let remainder = if ((a_u128 * b_u128) % 1000000000 == 0) {
            0
        } else {
            1
        };
        (remainder, ((a_u128 * b_u128 / 1000000000) as u64))
    }

    fun mul_internal_u128(
        a: u128,
        b: u128
    ): (u128, u128) {
        let a_u256 = (a as u256);
        let b_u256 = (b as u256);
        let remainder_flag = if ((a_u256 * b_u256) % 1000000000 == 0) {
            0
        } else {
            1
        };
        (remainder_flag, (((a_u256 * b_u256) / 1000000000) as u128))
    }

    fun quick_sort(input: vector<u128>): vector<u128> {
        let length = vector::length(&input);
        if (length <= 1) {
            return input;
        };

        let pivot = *vector::borrow(&input, 0);
        let mut less = vector[];
        let mut equal = vector[];
        let mut greater = vector[];

        let mut index = length;
        while (index > 0) {
            let current_index = index - 1;
            index = current_index;
            let value = *vector::borrow(&input, current_index);

            if (value < pivot) {
                vector::push_back(&mut less, value);
                continue;
            };
            if (value == pivot) {
                vector::push_back(&mut equal, value);
                continue;
            };
            vector::push_back(&mut greater, value);
        };

        let mut sorted = vector[];
        vector::append(&mut sorted, quick_sort(less));
        vector::append(&mut sorted, equal);
        vector::append(&mut sorted, quick_sort(greater));
        sorted
    }

    public fun mul(a: u64, b: u64): u64 {
        let (_, result) = mul_internal(a, b);
        result
    }

    public fun mul_u128(
        a: u128,
        b: u128
    ): u128 {
        let (_, result) = mul_internal_u128(a, b);
        result
    }

    public fun mul_round_up(
        a: u64,
        b: u64
    ): u64 {
        let (result, remainder) = mul_internal(a, b);
        result + remainder
    }

    public fun div(
        numerator: u64,
        denominator: u64
    ): u64 {
        let (_, result) = div_internal(numerator, denominator);
        result
    }

    public fun div_u128(
        numerator: u128,
        denominator: u128
    ): u128 {
        let (_, result) = div_internal_u128(numerator, denominator);
        result
    }

    public fun div_round_up(
        numerator: u64,
        denominator: u64
    ): u64 {
        let (quotient, remainder) = div_internal(numerator, denominator);
        quotient + remainder
    }

    public fun median(values: vector<u128>): u128 {
        let length = vector::length(&values);
        if (length == 0) {
            return 0;
        };

        let sorted_values = quick_sort(values);

        if (length % 2 == 0) {
            let left_middle = *vector::borrow(&sorted_values, length / 2 - 1);
            let right_middle = *vector::borrow(&sorted_values, length / 2);
            mul_u128(left_middle + right_middle, 1000000000 / 2)
        } else {
            *vector::borrow(&sorted_values, length / 2)
        }
    }

    public fun sqrt(
        value: u64,
        scale: u64
    ): u64 {
        assert!(scale <= 1000000000, 13);
        let scale_factor = ((1000000000 / scale) as u128);
        (((u128::sqrt((value as u128) * scale_factor * 1000000000) / scale_factor) as u64))
    }

    public fun min(a: u64, b: u64): u64 {
        if (a > b) {
            b
        } else {
            a
        }
    }

    public fun max(a: u64, b: u64): u64 {
        if (a > b) {
            a
        } else {
            b
        }
    }
}