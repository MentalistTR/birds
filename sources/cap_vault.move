// Decompiled by SuiGPT
module birds::cap_vault {

    // ----- Use Statements -----

    // ----- Structs -----

    public struct CAP_VAULT has drop {
        dummy_field: bool,
    }

    public struct CapVault<T0: key> has store, key {
        id: object::UID,
        admin_cap: option::Option<T0>,
        new_owner: option::Option<address>,
        og_owner: option::Option<address>,
    }

    // ----- Functions -----

    fun init(
        cap_vault: CAP_VAULT,
        ctx: &tx_context::TxContext
    ) {
    }

    public(package) fun createVault<T: store + key>(
        ctx: &mut tx_context::TxContext
    ) {
        let vault = CapVault<T> {
            id: object::new(ctx),
            admin_cap: option::none<T>(),
            new_owner: option::none<address>(),
            og_owner: option::none<address>(),
        };
        transfer::share_object(vault);
    }

    public fun transfer_cap<T: store + key>(
        cap: T,
        new_owner: address,
        cap_vault: &mut CapVault<T>,
        ctx: &mut tx_context::TxContext
    ) {
        option::fill(&mut cap_vault.admin_cap, cap);
        option::fill(&mut cap_vault.new_owner, new_owner);
        option::fill(&mut cap_vault.og_owner, ctx.sender());
    }

    public fun revoke_cap<T: store + key>(
        cap_vault: &mut CapVault<T>,
        ctx: &tx_context::TxContext
    ): T {
        assert!(
            option::is_some(&cap_vault.og_owner) && 
            *option::borrow(&cap_vault.og_owner) == ctx.sender(),
            1001
        );
        option::extract(&mut cap_vault.og_owner);
        option::extract(&mut cap_vault.new_owner);
        option::extract(&mut cap_vault.admin_cap)
    }

    public fun claim_cap<T: store + key>(
        cap_vault: &mut CapVault<T>,
        ctx: &tx_context::TxContext
    ): T {
        assert!(
            option::is_some(&cap_vault.new_owner) && 
            *option::borrow(&cap_vault.new_owner) == ctx.sender(),
            1001
        );
        option::extract(&mut cap_vault.og_owner);
        option::extract(&mut cap_vault.new_owner);
        option::extract(&mut cap_vault.admin_cap)
    }
}