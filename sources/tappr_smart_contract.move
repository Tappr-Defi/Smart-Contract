#[allow(unused_field, unused_use, duplicate_alias, lint(coin_field))]
module tappr_smart_contract::wallet_address_authentication {
    use std::string::{String, utf8};
    use sui::event;
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;

    const E_INSUFFICIENT_BALANCE: u64 = 0;
    const E_INVALID_AMOUNT: u64 = 1;

    public struct Wallet has key, store {
        id: UID,
        owner: address,
        balance: Coin<SUI>,
    }

    public struct BalanceChecker has drop {
        balance: u64,
        owner: address,
    }

    public struct WalletCreatedEvent has copy, drop {
        wallet_id: address,
        owner: address,
        timestamp: u64,
    }

    public struct DepositEvent has copy, drop {
        wallet_id: address,
        amount: u64,
        timestamp: u64,
    }

    public struct TransferToAddressEvent has copy, drop {
        source_wallet_id: address,
        recipient: address,
        amount: u64,
        timestamp: u64,
    }

    public struct ReceiveEvent has copy, drop {
        wallet_id: address,
        amount: u64,
        sender: address,
        timestamp: u64,
    }

    public struct TransferToWalletEvent has copy, drop {
        wallet_id: address,
        dest_wallet_id: address,
        amount: u64,
        timestamp: u64,
    }

    public struct TransferToTheAddressEvent has copy, drop {
        sender: address,
        recipient: address,
        amount: u64,
        timestamp: u64,
    }

    public fun balance_of(wallet: &Wallet): u64 {
        coin::value(&wallet.balance)
    }

    public fun owner_of(wallet: &Wallet): address {
        wallet.owner
    }

    public entry fun create_wallet(ctx: &mut TxContext) {
        let wallet = Wallet {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            balance: coin::zero<SUI>(ctx),
        };
        let wallet_id = object::uid_to_address(&wallet.id);
        event::emit(WalletCreatedEvent {
            wallet_id,
            owner: tx_context::sender(ctx),
            timestamp: tx_context::epoch(ctx),
        });
        transfer::public_transfer(wallet, tx_context::sender(ctx));
    }

    public entry fun create_address(owner: address, ctx: &mut TxContext) {
        let wallet = Wallet {
            id: object::new(ctx),
            owner,
            balance: coin::zero<SUI>(ctx),
        };
        let wallet_id = object::uid_to_address(&wallet.id);
        event::emit(WalletCreatedEvent {
            wallet_id,
            owner,
            timestamp: tx_context::epoch(ctx),
        });
        transfer::public_transfer(wallet, owner);
    }

    public entry fun deposit(wallet: &mut Wallet, coin: Coin<SUI>, ctx: &mut TxContext) {
        let amount = coin::value(&coin);
        assert!(amount > 0, E_INVALID_AMOUNT);
        coin::join(&mut wallet.balance, coin);
        event::emit(DepositEvent {
            wallet_id: object::uid_to_address(&wallet.id),
            amount,
            timestamp: tx_context::epoch(ctx),
        });
    }

    public entry fun transfer_to_wallet(
        source_wallet: &mut Wallet,
        dest_wallet: &mut Wallet,
        amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(amount > 0, E_INVALID_AMOUNT);
        assert!(coin::value(&source_wallet.balance) >= amount, E_INSUFFICIENT_BALANCE);

        let transferred_coin = coin::split(&mut source_wallet.balance, amount, ctx);
        coin::join(&mut dest_wallet.balance, transferred_coin);
        event::emit(TransferToWalletEvent {
            wallet_id: object::uid_to_address(&source_wallet.id),
            dest_wallet_id: object::uid_to_address(&dest_wallet.id),
            amount,
            timestamp: tx_context::epoch(ctx),
        });
    }

    public entry fun transfer_to_address(
        source_wallet: &mut Wallet,
        recipient: address,
        amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(amount > 0, E_INVALID_AMOUNT);
        assert!(coin::value(&source_wallet.balance) >= amount, E_INSUFFICIENT_BALANCE);

        let transferred_coin = coin::split(&mut source_wallet.balance, amount, ctx);
        transfer::public_transfer(transferred_coin, recipient);
        event::emit(TransferToAddressEvent {
            source_wallet_id: object::uid_to_address(&source_wallet.id),
            recipient,
            amount,
            timestamp: tx_context::epoch(ctx),
        });
    }


    public entry fun transfer_tothe_address(
        coin: &mut Coin<SUI>,
        recipient: address,
        amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(amount > 0, E_INVALID_AMOUNT);
        assert!(coin::value(coin) >= amount, E_INSUFFICIENT_BALANCE);

        let transferred_coin = coin::split(coin, amount, ctx);
        transfer::public_transfer(transferred_coin, recipient);
        event::emit(TransferToTheAddressEvent {
            sender: tx_context::sender(ctx),
            recipient,
            amount,
            timestamp: tx_context::epoch(ctx),
        });
    }

    public entry fun receive(wallet: &mut Wallet, coin: Coin<SUI>, ctx: &mut TxContext) {
        let amount = coin::value(&coin);
        assert!(amount > 0, E_INVALID_AMOUNT);
        coin::join(&mut wallet.balance, coin);
        event::emit(ReceiveEvent {
            wallet_id: object::uid_to_address(&wallet.id),
            amount,
            sender: tx_context::sender(ctx),
            timestamp: tx_context::epoch(ctx),
        });
    }
}

