#[test_only]
module tappr_smart_contract::wallet_address_authentication_tests {
    use tappr_smart_contract::wallet_address_authentication as wallet;
    use sui::test_scenario;
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;

    const OWNER: address = @0x123;
    const RECIPIENT: address = @0x456;
    const NEW_OWNER: address = @0x789; // New address for create_address test

    fun setup_wallet(): test_scenario::Scenario {
        let mut scenario = test_scenario::begin(OWNER);
        test_scenario::next_tx(&mut scenario, OWNER);
        {
            wallet::create_wallet(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, OWNER);
        scenario
    }

    #[test]
    fun test_create_wallet() {
        let mut scenario = test_scenario::begin(OWNER);
        wallet::create_wallet(test_scenario::ctx(&mut scenario));

        test_scenario::next_tx(&mut scenario, OWNER);
        {
            let wallet = test_scenario::take_from_sender<wallet::Wallet>(&scenario);
            assert!(wallet::balance_of(&wallet) == 0, 1);
            assert!(wallet::owner_of(&wallet) == OWNER, 2);
            test_scenario::return_to_sender(&scenario, wallet);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_create_address() {
        let mut scenario = test_scenario::begin(OWNER);
        wallet::create_address(NEW_OWNER, test_scenario::ctx(&mut scenario));

        test_scenario::next_tx(&mut scenario, NEW_OWNER);
        {
            let wallet = test_scenario::take_from_sender<wallet::Wallet>(&scenario);
            assert!(wallet::balance_of(&wallet) == 0, 1);
            assert!(wallet::owner_of(&wallet) == NEW_OWNER, 2);
            test_scenario::return_to_sender(&scenario, wallet);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_deposit() {
        let mut scenario = setup_wallet();
        {
            let mut wallet = test_scenario::take_from_sender<wallet::Wallet>(&scenario);
            let coin = coin::mint_for_testing<SUI>(100, test_scenario::ctx(&mut scenario));
            wallet::deposit(&mut wallet, coin, test_scenario::ctx(&mut scenario));
            assert!(wallet::balance_of(&wallet) == 100, 0);
            test_scenario::return_to_sender(&scenario, wallet);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = wallet::E_INVALID_AMOUNT)]
    fun test_deposit_zero() {
        let mut scenario = setup_wallet();
        {
            let mut wallet = test_scenario::take_from_sender<wallet::Wallet>(&scenario);
            let coin = coin::mint_for_testing<SUI>(0, test_scenario::ctx(&mut scenario));
            wallet::deposit(&mut wallet, coin, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, wallet);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_transfer_to_wallet() {
        let mut scenario = test_scenario::begin(OWNER);
        {
            wallet::create_wallet(test_scenario::ctx(&mut scenario));
            test_scenario::next_tx(&mut scenario, OWNER);
            let mut source_wallet = test_scenario::take_from_sender<wallet::Wallet>(&scenario);
            test_scenario::next_tx(&mut scenario, RECIPIENT);
            wallet::create_wallet(test_scenario::ctx(&mut scenario));
            test_scenario::next_tx(&mut scenario, RECIPIENT);
            let mut dest_wallet = test_scenario::take_from_sender<wallet::Wallet>(&scenario);
            test_scenario::next_tx(&mut scenario, OWNER);
            let coin = coin::mint_for_testing<SUI>(100, test_scenario::ctx(&mut scenario));
            wallet::deposit(&mut source_wallet, coin, test_scenario::ctx(&mut scenario));
            wallet::transfer_to_wallet(&mut source_wallet, &mut dest_wallet, 60, test_scenario::ctx(&mut scenario));
            assert!(wallet::balance_of(&source_wallet) == 40, 0);
            assert!(wallet::balance_of(&dest_wallet) == 60, 0);
            test_scenario::return_to_sender(&scenario, source_wallet);
            test_scenario::next_tx(&mut scenario, RECIPIENT);
            test_scenario::return_to_sender(&scenario, dest_wallet);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = wallet::E_INSUFFICIENT_BALANCE)]
    fun test_transfer_to_wallet_insufficient_balance() {
        let mut scenario = test_scenario::begin(OWNER);
        {
            wallet::create_wallet(test_scenario::ctx(&mut scenario));
            test_scenario::next_tx(&mut scenario, OWNER);
            let mut source_wallet = test_scenario::take_from_sender<wallet::Wallet>(&scenario);
            test_scenario::next_tx(&mut scenario, RECIPIENT);
            wallet::create_wallet(test_scenario::ctx(&mut scenario));
            test_scenario::next_tx(&mut scenario, RECIPIENT);
            let mut dest_wallet = test_scenario::take_from_sender<wallet::Wallet>(&scenario);
            test_scenario::next_tx(&mut scenario, OWNER);
            let coin = coin::mint_for_testing<SUI>(100, test_scenario::ctx(&mut scenario));
            wallet::deposit(&mut source_wallet, coin, test_scenario::ctx(&mut scenario));
            wallet::transfer_to_wallet(&mut source_wallet, &mut dest_wallet, 150, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, source_wallet);
            test_scenario::next_tx(&mut scenario, RECIPIENT);
            test_scenario::return_to_sender(&scenario, dest_wallet);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = wallet::E_INVALID_AMOUNT)]
    fun test_transfer_to_wallet_zero() {
        let mut scenario = test_scenario::begin(OWNER);
        {
            wallet::create_wallet(test_scenario::ctx(&mut scenario));
            test_scenario::next_tx(&mut scenario, OWNER);
            let mut source_wallet = test_scenario::take_from_sender<wallet::Wallet>(&scenario);
            test_scenario::next_tx(&mut scenario, RECIPIENT);
            wallet::create_wallet(test_scenario::ctx(&mut scenario));
            test_scenario::next_tx(&mut scenario, RECIPIENT);
            let mut dest_wallet = test_scenario::take_from_sender<wallet::Wallet>(&scenario);
            test_scenario::next_tx(&mut scenario, OWNER);
            let coin = coin::mint_for_testing<SUI>(100, test_scenario::ctx(&mut scenario));
            wallet::deposit(&mut source_wallet, coin, test_scenario::ctx(&mut scenario));
            wallet::transfer_to_wallet(&mut source_wallet, &mut dest_wallet, 0, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, source_wallet);
            test_scenario::next_tx(&mut scenario, RECIPIENT);
            test_scenario::return_to_sender(&scenario, dest_wallet);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_transfer_to_address() {
        let mut scenario = test_scenario::begin(OWNER);
        {
            wallet::create_wallet(test_scenario::ctx(&mut scenario));
            test_scenario::next_tx(&mut scenario, OWNER);
            let mut source_wallet = test_scenario::take_from_sender<wallet::Wallet>(&scenario);
            let coin = coin::mint_for_testing<SUI>(100, test_scenario::ctx(&mut scenario));
            wallet::deposit(&mut source_wallet, coin, test_scenario::ctx(&mut scenario));
            wallet::transfer_to_address(&mut source_wallet, RECIPIENT, 60, test_scenario::ctx(&mut scenario));
            assert!(wallet::balance_of(&source_wallet) == 40, 0);
            test_scenario::next_tx(&mut scenario, RECIPIENT);
            let received_coin = test_scenario::take_from_sender<Coin<SUI>>(&scenario);
            assert!(coin::value(&received_coin) == 60, 0);
            test_scenario::return_to_sender(&scenario, received_coin);
            test_scenario::next_tx(&mut scenario, OWNER);
            test_scenario::return_to_sender(&scenario, source_wallet);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = wallet::E_INSUFFICIENT_BALANCE)]
    fun test_transfer_to_address_insufficient_balance() {
        let mut scenario = test_scenario::begin(OWNER);
        {
            wallet::create_wallet(test_scenario::ctx(&mut scenario));
            test_scenario::next_tx(&mut scenario, OWNER);
            let mut source_wallet = test_scenario::take_from_sender<wallet::Wallet>(&scenario);
            let coin = coin::mint_for_testing<SUI>(100, test_scenario::ctx(&mut scenario));
            wallet::deposit(&mut source_wallet, coin, test_scenario::ctx(&mut scenario));
            wallet::transfer_to_address(&mut source_wallet, RECIPIENT, 150, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, source_wallet);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = wallet::E_INVALID_AMOUNT)]
    fun test_transfer_to_address_zero() {
        let mut scenario = test_scenario::begin(OWNER);
        {
            wallet::create_wallet(test_scenario::ctx(&mut scenario));
            test_scenario::next_tx(&mut scenario, OWNER);
            let mut source_wallet = test_scenario::take_from_sender<wallet::Wallet>(&scenario);
            let coin = coin::mint_for_testing<SUI>(100, test_scenario::ctx(&mut scenario));
            wallet::deposit(&mut source_wallet, coin, test_scenario::ctx(&mut scenario));
            wallet::transfer_to_address(&mut source_wallet, RECIPIENT, 0, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, source_wallet);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_receive() {
        let mut scenario = test_scenario::begin(OWNER);
        {
            wallet::create_wallet(test_scenario::ctx(&mut scenario));
            test_scenario::next_tx(&mut scenario, OWNER);
            let mut wallet = test_scenario::take_from_sender<wallet::Wallet>(&scenario);
            let coin = coin::mint_for_testing<SUI>(50, test_scenario::ctx(&mut scenario));
            wallet::receive(&mut wallet, coin, test_scenario::ctx(&mut scenario));
            assert!(wallet::balance_of(&wallet) == 50, 0);
            test_scenario::return_to_sender(&scenario, wallet);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = wallet::E_INVALID_AMOUNT)]
    fun test_receive_zero() {
        let mut scenario = test_scenario::begin(OWNER);
        {
            wallet::create_wallet(test_scenario::ctx(&mut scenario));
            test_scenario::next_tx(&mut scenario, OWNER);
            let mut wallet = test_scenario::take_from_sender<wallet::Wallet>(&scenario);
            let coin = coin::mint_for_testing<SUI>(0, test_scenario::ctx(&mut scenario));
            wallet::receive(&mut wallet, coin, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, wallet);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_transfer_tothe_address() {
        let mut scenario = test_scenario::begin(OWNER);
        {
            let coin = coin::mint_for_testing<SUI>(100, test_scenario::ctx(&mut scenario));
            transfer::public_transfer(coin, OWNER);
            test_scenario::next_tx(&mut scenario, OWNER);
            let mut coin = test_scenario::take_from_sender<Coin<SUI>>(&scenario);
            wallet::transfer_tothe_address(&mut coin, RECIPIENT, 60, test_scenario::ctx(&mut scenario));
            assert!(coin::value(&coin) == 40, 0);
            test_scenario::next_tx(&mut scenario, RECIPIENT);
            let received_coin = test_scenario::take_from_sender<Coin<SUI>>(&scenario);
            assert!(coin::value(&received_coin) == 60, 0);
            test_scenario::return_to_sender(&scenario, received_coin);
            test_scenario::next_tx(&mut scenario, OWNER);
            test_scenario::return_to_sender(&scenario, coin);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = wallet::E_INSUFFICIENT_BALANCE)]
    fun test_transfer_tothe_address_insufficient_balance() {
        let mut scenario = test_scenario::begin(OWNER);
        {
            let coin = coin::mint_for_testing<SUI>(100, test_scenario::ctx(&mut scenario));
            transfer::public_transfer(coin, OWNER);
            test_scenario::next_tx(&mut scenario, OWNER);
            let mut coin = test_scenario::take_from_sender<Coin<SUI>>(&scenario);
            wallet::transfer_tothe_address(&mut coin, RECIPIENT, 150, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, coin);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = wallet::E_INVALID_AMOUNT)]
    fun test_transfer_tothe_address_zero() {
        let mut scenario = test_scenario::begin(OWNER);
        {
            let coin = coin::mint_for_testing<SUI>(100, test_scenario::ctx(&mut scenario));
            transfer::public_transfer(coin, OWNER);
            test_scenario::next_tx(&mut scenario, OWNER);
            let mut coin = test_scenario::take_from_sender<Coin<SUI>>(&scenario);
            wallet::transfer_tothe_address(&mut coin, RECIPIENT, 0, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, coin);
        };
        test_scenario::end(scenario);
    }
}

