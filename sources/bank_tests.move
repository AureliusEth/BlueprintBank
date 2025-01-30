#[test_only]
module 0x1::bank_tests {
   use sui::coin::{Self, Coin, TreasuryCap};
   use 0x1::bank::{Self, AssetBank, Receipt, receipt_amount}; 
   use sui::sui::SUI;
   use 0x1::fake_coin::{Self, FAKE_COIN};
   use sui::test_scenario::{Self, Scenario};

   const ALICE: address = @0xA11CE;
   const DEPOSIT_AMOUNT: u64 = 100;
   const BANK_EMPTY: u64 = 1;
   const BANK_INSUFFECIENT_BALANCE: u64 = 2;
   const ZERO_DEPOSIT: u64 = 3;
   const BANK_FIELD_ERROR: u64 = 4;
   const RECEIPT_INVALID: u64 = 5;
   const WITHDRAWAL_AMOUNT_INVALID: u64 = 6;
   #[test]
   fun test_init_and_deposit() {
       let mut scenario = test_scenario::begin(ALICE);
       
       test_scenario::next_tx(&mut scenario, ALICE);
       {
           bank::init_for_testing(test_scenario::ctx(&mut scenario));
       };

       test_scenario::next_tx(&mut scenario, ALICE);
       {

           //Take the shared bank from the module that intialised it 
           let mut bank = test_scenario::take_shared<AssetBank>(&scenario);

           //Mint SUI for testing
           let coin = coin::mint_for_testing<SUI>(DEPOSIT_AMOUNT, test_scenario::ctx(&mut scenario));

           //Call our deposit function
           bank::deposit<SUI>(&mut bank, coin, test_scenario::ctx(&mut scenario));

           //Check all bank fields were updated correctly post deposit
           let (deposits, active_receipts) = bank::test_get_bank_fields(&bank);
           assert!(deposits == 1, BANK_FIELD_ERROR);
           assert!(active_receipts == 1, BANK_FIELD_ERROR);
           test_scenario::return_shared(bank);
       };

       test_scenario::next_tx(&mut scenario, ALICE);
       {
           // Take the generated Receipt 
           let receipt = test_scenario::take_from_sender<Receipt<Coin<SUI>>>(&scenario);

           // verifies receipt amount and therefore its creation
           assert!(receipt_amount(&receipt) == DEPOSIT_AMOUNT, RECEIPT_INVALID);
           test_scenario::return_to_sender(&scenario, receipt);
       };

       test_scenario::end(scenario);
   }

   #[test]
   #[expected_failure]
   fun test_fail_init_and_deposit() {
       let mut scenario = test_scenario::begin(ALICE);
       
       test_scenario::next_tx(&mut scenario, ALICE);
       {
           bank::init_for_testing(test_scenario::ctx(&mut scenario));
       };

       test_scenario::next_tx(&mut scenario, ALICE);
       {

           //Take the shared bank from the module that intialised it 
           let mut bank = test_scenario::take_shared<AssetBank>(&scenario);

           // Init coin with a zero value 
           let coin = coin::zero<SUI>(test_scenario::ctx(&mut scenario));

           // Call our deposit function
           bank::deposit<SUI>(&mut bank, coin, test_scenario::ctx(&mut scenario));
           test_scenario::return_shared(bank);
       };
       test_scenario::end(scenario);
   }

   #[test]
   fun test_deposit_and_withdraw() {
       let mut scenario = test_scenario::begin(ALICE);
       test_scenario::next_tx(&mut scenario, ALICE);
       {
           bank::init_for_testing(test_scenario::ctx(&mut scenario));
       };

       test_scenario::next_tx(&mut scenario, ALICE);
       {
           let mut bank = test_scenario::take_shared<AssetBank>(&scenario);
           let coin = coin::mint_for_testing<SUI>(DEPOSIT_AMOUNT, test_scenario::ctx(&mut scenario));
           bank::deposit<SUI>(&mut bank, coin, test_scenario::ctx(&mut scenario));
           test_scenario::return_shared(bank);
       };

       test_scenario::next_tx(&mut scenario, ALICE);
       {
           let mut bank = test_scenario::take_shared<AssetBank>(&scenario);
           let receipt = test_scenario::take_from_sender<Receipt<Coin<SUI>>>(&scenario);

           // Withdraw the users Receipt
           bank::withdraw<SUI>(&mut bank, receipt, test_scenario::ctx(&mut scenario));
           test_scenario::return_shared(bank);
       };

       test_scenario::next_tx(&mut scenario, ALICE);
       {
           let coin = test_scenario::take_from_sender<Coin<SUI>>(&scenario);
           assert!(coin::value(&coin) == DEPOSIT_AMOUNT, WITHDRAWAL_AMOUNT_INVALID);
           test_scenario::return_to_sender(&scenario, coin);
       };

       test_scenario::end(scenario);
   }

   #[test]
   fun test_fake_coin_deposit_and_withdraw() {
       let mut scenario = test_scenario::begin(ALICE);

       test_scenario::next_tx(&mut scenario, ALICE);
       {
           let (treasury_cap, initial_supply) = fake_coin::init_fake_coin(test_scenario::ctx(&mut scenario));

           //Give the intial supply to the sender
           transfer::public_transfer(initial_supply, tx_context::sender(test_scenario::ctx(&mut scenario)));

           // Give the treasury capability to the sender
           transfer::public_transfer(treasury_cap, tx_context::sender(test_scenario::ctx(&mut scenario)));
       };

       test_scenario::next_tx(&mut scenario, ALICE);
       {
           bank::init_for_testing(test_scenario::ctx(&mut scenario));
       };

       test_scenario::next_tx(&mut scenario, ALICE);
       {
           let mut bank = test_scenario::take_shared<AssetBank>(&scenario);

           // Take the treasury capability so we can mint fake token
           let mut treasury_cap = test_scenario::take_from_sender<TreasuryCap<FAKE_COIN>>(&scenario);
           let fake_coin = fake_coin::mint(&mut treasury_cap, DEPOSIT_AMOUNT, test_scenario::ctx(&mut scenario));

           //Deoisit fake coin
           bank::deposit<FAKE_COIN>(&mut bank, fake_coin, test_scenario::ctx(&mut scenario));
           let (deposits, active_receipts) = bank::test_get_bank_fields(&bank);
           assert!(deposits == 1, BANK_FIELD_ERROR);
           assert!(active_receipts == 1, BANK_FIELD_ERROR );
           test_scenario::return_to_sender(&scenario, treasury_cap);
           test_scenario::return_shared(bank);
       };

       test_scenario::next_tx(&mut scenario, ALICE);
       {
           let receipt = test_scenario::take_from_sender<Receipt<Coin<FAKE_COIN>>>(&scenario);
           assert!(receipt_amount(&receipt) == DEPOSIT_AMOUNT, WITHDRAWAL_AMOUNT_INVALID);
           test_scenario::return_to_sender(&scenario, receipt);
       };

       test_scenario::next_tx(&mut scenario, ALICE);
       {
           let mut bank = test_scenario::take_shared<AssetBank>(&scenario);
           let receipt = test_scenario::take_from_sender<Receipt<Coin<FAKE_COIN>>>(&scenario);
           bank::withdraw<FAKE_COIN>(&mut bank, receipt, test_scenario::ctx(&mut scenario));
           test_scenario::return_shared(bank);
       };

       test_scenario::next_tx(&mut scenario, ALICE);
       {
           let fake_coin = test_scenario::take_from_sender<Coin<FAKE_COIN>>(&scenario);
           assert!(coin::value(&fake_coin) == DEPOSIT_AMOUNT, 2);
           test_scenario::return_to_sender(&scenario, fake_coin);
       };

       test_scenario::end(scenario);
   }

   #[test]
   fun test_multi_coin_deposit_and_withdraw() {
       let mut scenario = test_scenario::begin(ALICE);

       // Initialize bank and fake coin
       test_scenario::next_tx(&mut scenario, ALICE);
       {
           bank::init_for_testing(test_scenario::ctx(&mut scenario));
           let (treasury_cap, initial_supply) = fake_coin::init_fake_coin(test_scenario::ctx(&mut scenario));
           transfer::public_transfer(initial_supply, tx_context::sender(test_scenario::ctx(&mut scenario)));
           transfer::public_transfer(treasury_cap, tx_context::sender(test_scenario::ctx(&mut scenario)));
       };

       // Deposit both SUI and FAKE_COIN
       test_scenario::next_tx(&mut scenario, ALICE);
       {
           let mut bank = test_scenario::take_shared<AssetBank>(&scenario);
           
           // Deposit SUI
           let sui_coin = coin::mint_for_testing<SUI>(DEPOSIT_AMOUNT, test_scenario::ctx(&mut scenario));
           bank::deposit<SUI>(&mut bank, sui_coin, test_scenario::ctx(&mut scenario));
           
           // Deposit FAKE_COIN
           let mut treasury_cap = test_scenario::take_from_sender<TreasuryCap<FAKE_COIN>>(&scenario);
           let fake_coin = fake_coin::mint(&mut treasury_cap, DEPOSIT_AMOUNT, test_scenario::ctx(&mut scenario));
           bank::deposit<FAKE_COIN>(&mut bank, fake_coin, test_scenario::ctx(&mut scenario));
           
           // Verify both deposits
           let (deposits, active_receipts) = bank::test_get_bank_fields(&bank);
           assert!(deposits == 2, BANK_FIELD_ERROR);
           assert!(active_receipts == 2, BANK_FIELD_ERROR);
           
           test_scenario::return_to_sender(&scenario, treasury_cap);
           test_scenario::return_shared(bank);
       };

       // Verify both receipts
       test_scenario::next_tx(&mut scenario, ALICE);
       {
           let sui_receipt = test_scenario::take_from_sender<Receipt<Coin<SUI>>>(&scenario);
           let fake_receipt = test_scenario::take_from_sender<Receipt<Coin<FAKE_COIN>>>(&scenario);
           
           assert!(receipt_amount(&sui_receipt) == DEPOSIT_AMOUNT, RECEIPT_INVALID);
           assert!(receipt_amount(&fake_receipt) == DEPOSIT_AMOUNT, RECEIPT_INVALID);
           
           test_scenario::return_to_sender(&scenario, sui_receipt);
           test_scenario::return_to_sender(&scenario, fake_receipt);
       };

       // Withdraw both coins
       test_scenario::next_tx(&mut scenario, ALICE);
       {
           let mut bank = test_scenario::take_shared<AssetBank>(&scenario);
           
           // Withdraw SUI
           let sui_receipt = test_scenario::take_from_sender<Receipt<Coin<SUI>>>(&scenario);
           bank::withdraw<SUI>(&mut bank, sui_receipt, test_scenario::ctx(&mut scenario));
           
           // Withdraw FAKE_COIN
           let fake_receipt = test_scenario::take_from_sender<Receipt<Coin<FAKE_COIN>>>(&scenario);
           bank::withdraw<FAKE_COIN>(&mut bank, fake_receipt, test_scenario::ctx(&mut scenario));
           
           // Verify both withdrawals
           let (deposits, active_receipts) = bank::test_get_bank_fields(&bank);
           assert!(deposits == 2, BANK_FIELD_ERROR); // Total deposits stays the same
           assert!(active_receipts == 0, BANK_FIELD_ERROR); // No active receipts after withdrawal
           
           test_scenario::return_shared(bank);
       };

       // Verify withdrawn amounts
       test_scenario::next_tx(&mut scenario, ALICE);
       {
           let sui_coin = test_scenario::take_from_sender<Coin<SUI>>(&scenario);
           let fake_coin = test_scenario::take_from_sender<Coin<FAKE_COIN>>(&scenario);
           
           assert!(coin::value(&sui_coin) == DEPOSIT_AMOUNT, WITHDRAWAL_AMOUNT_INVALID);
           assert!(coin::value(&fake_coin) == DEPOSIT_AMOUNT, WITHDRAWAL_AMOUNT_INVALID);
           
           test_scenario::return_to_sender(&scenario, sui_coin);
           test_scenario::return_to_sender(&scenario, fake_coin);
       };

       test_scenario::end(scenario);
   }
}
