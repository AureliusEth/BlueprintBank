module 0x1::bank {

    /// Import necessary Sui framework dependencies
    use sui::dynamic_field as df;
    use sui::coin::{Self, Coin};
    use sui::event;
    use std::type_name::{Self, TypeName};

    /// Error constants for common failure conditions
    const BANK_EMPTY: u64 = 1;
    const BANK_INSUFFECIENT_BALANCE: u64 = 2;
    const ZERO_DEPOSIT: u64 = 3;

    public struct AssetBank has key {
        id: object::UID,

        /// Tracks number of total deposits to the bank
        deposits: u64,

        /// Tracks the number of active deposits and receipts
        activeReceipts: u64,
    }

    public struct Receipt<CoinType> has key {
        id: object::UID,

        nftNumber: u64,
        /// Corresponds directly to the deposit's position in the bank's table

        depositor: address,
        amount: u64,
    }

    /// Event emitted when a new deposit is made
    public struct Deposited has copy, drop {
        bank: object::ID,
        receipt: object::ID,
        amount: u64
    }

    /// Event emitted when a withdrawal occurs
    public struct Withdrew<phantom CoinType> has copy, drop {
        bank: object::ID,
        receipt: object::ID,
        amount: u64
    }

    /// Module initializer creates the first bank instance 
    fun init(ctx: &mut TxContext) {
        let bank = AssetBank{
            id: object::new(ctx),
            deposits: 0,
            activeReceipts: 0,
        };

        /// Make the bank a shared object so anyone can interact with it
        transfer::share_object(bank);
    }

    #[test_only]

    /// Test-only initialization function
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx)
    }

    public entry fun deposit<CoinType>(
        bank: &mut AssetBank,
        deposit_coin: Coin<CoinType>,
        ctx: &mut TxContext,
    ) {

        let amount = coin::value(&deposit_coin);

        /// Ensure the deposit amount is greater than zero
        assert!(amount > 0, ZERO_DEPOSIT);
        let coin_type_name = type_name::get<CoinType>();

        /// Check if some tokens already exists in the dynamic field
        if (df::exists_(&bank.id, coin_type_name)) {

        /// Borrow from df to add the existing coin
        let existing_coin: &mut Coin<CoinType> = df::borrow_mut(&mut bank.id, coin_type_name);
        coin::join(existing_coin, deposit_coin);
        } else {

        /// Add new coin to dynamic field
        df::add(&mut bank.id, coin_type_name, deposit_coin);
        };
    
        /// Update bank's tracking numbers
        bank.deposits = bank.deposits + 1;
        bank.activeReceipts = bank.activeReceipts + 1;
        
        /// Create a receipt NFT that acts as a claim for the users coins 
        let receipt = Receipt<Coin<CoinType>> {
            id: object::new(ctx),
            nftNumber: bank.deposits,
            depositor: tx_context::sender(ctx),
            amount
        };
        
        /// Emit deposit event for tracking purposes
        event::emit(Deposited {
            bank: object::uid_to_inner(&bank.id),
            receipt: object::uid_to_inner(&receipt.id),
            amount
        });
        
        /// Transfer the receipt to the depositor
        transfer::transfer(receipt, tx_context::sender(ctx));
    }

    /// To Withdraw coins from the bank using a receipt NFT
    public entry fun withdraw<CoinType>(
        bank: &mut AssetBank,
        receipt: Receipt<Coin<CoinType>>,
        ctx: &mut TxContext
    ) {

        /// Store receipt information for event emition before we destroy it
        let receipt_amount = receipt.amount;
        let receipt_id = object::uid_to_inner(&receipt.id);
        let depositor = receipt.depositor;
        let deposit_num = receipt.nftNumber;
        
        let coin_type_name = type_name::get<CoinType>();
        // Check if the tokens already exists in the dynamic field
        assert!(df::exists_(&bank.id, coin_type_name),BANK_EMPTY); 
        // Remove the exact coin that was deposited
        let mut deposit_coin = df::remove<TypeName, Coin<CoinType>>(&mut bank.id, coin_type_name);
        // Check before split so we get a good error
        assert!(coin::value(&deposit_coin) >= receipt_amount, BANK_INSUFFECIENT_BALANCE);
        // Take only whats needed
        let withdrawl_coin = coin::split(&mut deposit_coin, receipt_amount, ctx); 
        // Add the deposit coin back to the dynamic field
        df::add(&mut bank.id, coin_type_name, deposit_coin);
        // Transfer the coin back to the original depositor
        transfer::public_transfer(withdrawl_coin, depositor);
        // Clean up by burning the receipt and updating bank state
        burn(receipt);
        bank.activeReceipts = bank.activeReceipts - 1;
        
        /// Emit withdrawal event for tracking purposes
        event::emit(Withdrew<CoinType> {
            bank: object::uid_to_inner(&bank.id),
            receipt: receipt_id,
            amount: receipt_amount
        });
    }

    /// Internal function to burn receipt NFTs after withdrawal
    fun burn<CoinType>(receipt: Receipt<Coin<CoinType>>) {
        let Receipt { id, nftNumber: _, depositor: _, amount: _ } = receipt;
        object::delete(id);
    }

    /// Public accessor for receipt amount (useful for testing)
    #[test_only]
    public fun receipt_amount<CoinType>(receipt: &Receipt<Coin<CoinType>>): u64 {
        receipt.amount
    }
    /// Public accessor for bank fields (useful for testing)
    #[test_only]
    public fun test_get_bank_fields(bank: &AssetBank): (u64, u64) {
    (bank.deposits, bank.activeReceipts)
    }
}
