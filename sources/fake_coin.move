#[test_only]
module 0x1::fake_coin {
    use sui::coin::{Self, Coin, TreasuryCap};

    // Define the fake coin type
    public struct FAKE_COIN has drop {}

    // Initialize the fake coin and create its treasury capability
    public fun init_fake_coin(ctx: &mut TxContext): (TreasuryCap<FAKE_COIN>, Coin<FAKE_COIN>) {
        let (mut treasury_cap, metadata) = coin::create_currency(
            FAKE_COIN {}, // Pass the one-time witness
            9,           // Decimals
            b"FAKE",     // Symbol
            b"Fake Coin", // Name
            b"Test coin for testing purposes", // Description
            option::none(), // No additional metadata
            ctx
        );

        // Transfer metadata to the sender (not needed for testing, but good practice)
        transfer::public_transfer(metadata, tx_context::sender(ctx));

        // Mint an initial supply of fake coins
        let initial_supply = coin::mint(&mut treasury_cap, 1000000, ctx); // Mint 1,000,000 fake coins
        (treasury_cap, initial_supply)
    }

    // Mint additional fake coins
    public fun mint(treasury_cap: &mut TreasuryCap<FAKE_COIN>, amount: u64, ctx: &mut TxContext): Coin<FAKE_COIN> {
        coin::mint(treasury_cap, amount, ctx)
    }
}
