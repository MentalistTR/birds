// Decompiled by SuiGPT
module Archive::archieve {

    // ----- Use Statements -----

    use sui::table;
    use sui::ed25519;

    // ----- Structs -----

    public struct ARCHIEVE has drop {
        dummy_field: bool,
    }

    public struct UserArchieve has store, key {
        id: object::UID,
        peg_token_nonce: u128,
        depeg_token_nonce: u128,
        peg_nft_nonce: u128,
        depeg_nft_nonce: u128,
        peg_prey_nonce: u128,
        depeg_prey_nonce: u128,
        total_deposit: u64,
        total_withdraw: u64,
    }

    public struct UserReg has store, key {
        id: object::UID,
        users: table::Table<address, bool>,
    }

    // ----- Functions -----

    fun init(
        archive: ARCHIEVE,
        ctx: &mut tx_context::TxContext
    ) {
        let user_reg = UserReg {
            id: object::new(ctx),
            users: table::new<address, bool>(ctx),
        };
        transfer::public_share_object(user_reg);
    }

    public fun register(
        user_reg: &mut UserReg,
        ctx: &mut tx_context::TxContext
    ): UserArchieve {
        let sender = tx_context::sender(ctx);
        assert!(
            !table::contains<address, bool>(&user_reg.users, sender),
            8003
        );
        let user_archieve = UserArchieve {
            id: object::new(ctx),
            peg_token_nonce: 0,
            depeg_token_nonce: 0,
            peg_nft_nonce: 0,
            depeg_nft_nonce: 0,
            peg_prey_nonce: 0,
            depeg_prey_nonce: 0,
            total_deposit: 0,
            total_withdraw: 0,
        };
        table::add<address, bool>(&mut user_reg.users, sender, true);
        user_archieve
    }

    public fun verifySignature(
        message: vector<u8>,
        signature: vector<u8>,
        public_key_option: &option::Option<vector<u8>>
    ) {
        assert!(option::is_some(public_key_option), 8001);
        assert!(
            ed25519::ed25519_verify(
                &message,
                option::borrow(public_key_option),
                &signature
            ),
            8000
        );
    }

    public fun verUpdateTokenPegNonce(
        new_nonce: u128,
        user_archive: &mut UserArchieve
    ) {
        assert!(user_archive.peg_token_nonce < new_nonce, 8002);
        user_archive.peg_token_nonce = new_nonce;
    }

    public fun verUpdateTokenDepegNonce(
        new_nonce: u128,
        user_archive: &mut UserArchieve
    ) {
        assert!(user_archive.depeg_token_nonce < new_nonce, 8002);
        user_archive.depeg_token_nonce = new_nonce;
    }

    public fun verUpdatePreyPegNonce(
        new_nonce: u128,
        user_archive: &mut UserArchieve
    ) {
        assert!(user_archive.peg_prey_nonce < new_nonce, 8002);
        user_archive.peg_prey_nonce = new_nonce;
    }

    public fun increaseGetTokenDepegNonce(
        user_archive: &mut UserArchieve
    ): u128 {
        let current_nonce = user_archive.depeg_token_nonce;
        user_archive.depeg_token_nonce = current_nonce + 1;
        user_archive.depeg_token_nonce
    }

    public fun verUpdateNftPegNonce(
        new_nonce: u128,
        user_archive: &mut UserArchieve
    ) {
        assert!(user_archive.peg_nft_nonce < new_nonce, 8002);
        user_archive.peg_nft_nonce = new_nonce;
    }

    public fun verUpdateNftDepegNonce(
        new_nonce: u128,
        user_archive: &mut UserArchieve
    ) {
        assert!(user_archive.depeg_nft_nonce < new_nonce, 8002);
        user_archive.depeg_nft_nonce = new_nonce;
    }

    public fun increaseGetNftDepegNonce(
        user_archive: &mut UserArchieve
    ): u128 {
        user_archive.depeg_nft_nonce = user_archive.depeg_nft_nonce + 1;
        user_archive.depeg_nft_nonce
    }

    public fun increaseGetPreyDepegNonce(
        user_archive: &mut UserArchieve
    ): u128 {
        let current_nonce = user_archive.depeg_prey_nonce;
        user_archive.depeg_prey_nonce = current_nonce + 1;
        user_archive.depeg_prey_nonce
    }

    public fun increaseTotalDeposit(
        amount: u64,
        user_archive: &mut UserArchieve
    ): u64 {
        user_archive.total_deposit = user_archive.total_deposit + amount;
        user_archive.total_deposit
    }

    public fun decreaseToTalDeposit(
        amount: u64,
        user_archive: &mut UserArchieve
    ): u64 {
        assert!(user_archive.total_deposit >= amount, 8004);
        user_archive.total_deposit = user_archive.total_deposit - amount;
        user_archive.total_deposit
    }

    public fun increaseTotalWithdraw(
        amount: u64,
        user_archive: &mut UserArchieve
    ): u64 {
        user_archive.total_withdraw = user_archive.total_withdraw + amount;
        user_archive.total_withdraw
    }

    public fun decreaseToTalWithdraw(
        amount: u64,
        user_archive: &mut UserArchieve
    ): u64 {
        assert!(user_archive.total_withdraw >= amount, 8004);
        user_archive.total_withdraw = user_archive.total_withdraw - amount;
        user_archive.total_withdraw
    }
}