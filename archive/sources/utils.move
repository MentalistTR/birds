// Decompiled by SuiGPT
module Archive::utils {

    // ----- Use Statements -----

    use sui::token;
    use std::vector;
    use sui::display;
    use sui::vec_map;
    use std::string;
    use sui::tx_context;

    // ----- Functions -----

    public entry fun join<T>(
        token_a: &mut token::Token<T>,
        token_b: token::Token<T>
    ) {
        token::join(token_a, token_b);
    }

    public entry fun join_vec<T>(
    token: &mut token::Token<T>,
    mut tokens: vector<token::Token<T>> // 'mut' eklenerek mutable olarak tanımlandı
    ) {
    let mut length = vector::length(&tokens); // Length için de 'mut' tanımlandı
    while (length > 0) {
        token::join(token, vector::pop_back(&mut tokens)); // 'tokens' mutable olarak kullanılabilir
        length = length - 1;
    };
    vector::destroy_empty(tokens);
    }   

    public entry fun nftDisplay<T: store + key>(
        display: &display::Display<T>
    ): vec_map::VecMap<string::String, string::String> {
        *display::fields(display)
    }

    public fun split<T>(
        token: &mut token::Token<T>,
        amount: u64,
        ctx: &mut tx_context::TxContext
    ): token::Token<T> {
        token::split(token, amount, ctx)
    }
}