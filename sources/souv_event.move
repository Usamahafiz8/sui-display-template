module souv::souv_event {
    use sui::clock::{Clock, Self};
    use sui::event;
    use std::string::{String};

    const EWrongVersion: u64 = 0;
    const EEventExpired: u64 = 1;
    const EExceedsMintSupply: u64 = 2;
    const ENotAuthorized: u64 = 3;
    const VERSION: u64 = 1;

    public struct CreateNFT has key, store {
        id: UID,
        title_id: vector<String>,
        is_transferable: bool,
        mint_supply: u64,
        creator: address,
    }

    public struct CountEntry has store, drop {
        title_id: vector<String>,
        minted: u64,
    }

    public struct DynamicCounter has key, store {
        id: UID,
        version: u64,
        counts: vector<CountEntry>,
    }

    public struct Platform has key {
        id: UID,
        title_id: vector<String>,
        mint_number: u64,
        name: String,
        description: String,
        image_url: String,
    }

    public struct Public has key, store {
        id: UID,
        title_id: vector<String>,
        mint_number: u64,
        name: String,
        description: String,
        image_url: String,
    }

    public struct Event has key, store {
        id: UID,
        title_id: vector<String>,
        expiration: u64,
    }

    public struct MintEvent has copy, drop {
        object_id: address,
        title_id: vector<String>,
        mint_number: u64,
        name: String,
        description: String,
        image_url: String,
        is_transferable: bool,
    }

    public fun create_nft(
        title_id: vector<String>,
        is_transferable: bool,
        mint_supply: u64,
        ctx: &mut TxContext
    ): CreateNFT {
        CreateNFT {
            id: object::new(ctx),
            title_id,
            is_transferable,
            mint_supply,
            creator: tx_context::sender(ctx),
        }
    }

    public fun create_counter(ctx: &mut TxContext): DynamicCounter {
        DynamicCounter {
            id: object::new(ctx),
            version: VERSION,
            counts: vector::empty(),
        }
    }

    public fun new_event(
        nft: &CreateNFT,
        duration: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): Event {
        Event {
            id: object::new(ctx),
            title_id: nft.title_id,
            expiration: clock::timestamp_ms(clock) + duration,
        }
    }

    public fun update_mint_supply(
        nft: &mut CreateNFT,
        new_supply: u64,
        ctx: &mut TxContext
    ) {
        assert!(nft.creator == tx_context::sender(ctx), ENotAuthorized);
        nft.mint_supply = new_supply;
    }

    public fun incr_counter(counter: &mut DynamicCounter, title_id: vector<String>) {
        assert!(counter.version == VERSION, EWrongVersion);
        let mut i = 0;
        let len = vector::length(&counter.counts);
        while (i < len) {
            let entry = vector::borrow_mut(&mut counter.counts, i);
            if (entry.title_id == title_id) {
                entry.minted = entry.minted + 1;
                return;
            };
            i = i + 1;
        };
        vector::push_back(&mut counter.counts, CountEntry {
            title_id,
            minted: 1,
        });
    }

    public fun num_minted(counter: &DynamicCounter, title_id: vector<String>): u64 {
        let mut i = 0;
        let len = vector::length(&counter.counts);
        while (i < len) {
            let entry = vector::borrow(&counter.counts, i);
            if (entry.title_id == title_id) {
                return entry.minted;
            };
            i = i + 1;
        };
        0
    }

    fun check_mint_supply(nft: &CreateNFT, counter: &DynamicCounter) {
        let minted = num_minted(counter, nft.title_id);
        assert!(minted < nft.mint_supply, EExceedsMintSupply);
    }

    public fun mint_and_transfer(
        event: &Event,
        nft: &CreateNFT,
        counter: &mut DynamicCounter,
        recipient: address,
        name: String,
        description: String,
        image_url: String,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(event.expiration > clock::timestamp_ms(clock), EEventExpired);
        assert!(counter.version == VERSION, EWrongVersion);
        assert!(event.title_id == nft.title_id, EWrongVersion);
        check_mint_supply(nft, counter);

        let title_id = event.title_id;
        incr_counter(counter, title_id);
        let mint_number = num_minted(counter, title_id);
        let object_id: address;

        if (nft.is_transferable) {
            let poap = Public {
                id: object::new(ctx),
                title_id,
                mint_number,
                name,
                description,
                image_url,
            };
            object_id = object::uid_to_address(&poap.id);
            transfer::transfer(poap, recipient);
            event::emit(MintEvent {
                object_id,
                title_id,
                mint_number,
                name,
                description,
                image_url,
                is_transferable: true,
            });
        } else {
            let poap = Platform {
                id: object::new(ctx),
                title_id,
                mint_number,
                name,
                description,
                image_url,
            };
            object_id = object::uid_to_address(&poap.id);
            transfer::transfer(poap, recipient);
            event::emit(MintEvent {
                object_id,
                title_id,
                mint_number,
                name,
                description,
                image_url,
                is_transferable: false,
            });
        }
    }
}