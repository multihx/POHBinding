module poh_binding::example {
	use sui::vec_map::{Self, VecMap};
	use sui::event;

	const EInvalidPermission: u64 = 1;
	const ENotWhiteListed: u64 = 2;
	const ENoBindingDataForAddress: u64 = 3;

	public struct UserData has store, drop {
		data:vector<u8>
	}

	public struct Proof has key {
		id:UID,
		user_data: VecMap<address, UserData>,
		whitelisted_addresses: vector<address>,
		owner: address
	}

	// === Events ===
	public struct WhitelistUpdated has copy, drop{
		user: address,
		status: bool,
	}
 
	public struct Bound has copy, drop{
		addr: address,
		data: vector<u8>,
	}
  
	public struct Rebound has copy, drop{
		oldAddr: address,
		oldData: vector<u8>,
		newAddr: address,
		newData: vector<u8>,
	}

	// === Contract call ===
	public fun isWhitelisted(proof: &Proof, address: address): bool {
		vector::contains(&proof.whitelisted_addresses, &address)
	}
	
	public fun create(ctx: &mut TxContext){
		let owner = tx_context::sender(ctx);
		let list = vector[owner];
		let proof = Proof{
			id:object::new(ctx),
			user_data: vec_map::empty(),
			whitelisted_addresses: list,
	 		owner: ctx.sender() 
		};

		transfer::transfer(proof, owner)
	}

	public fun updateWhiteList(proof: &mut Proof, addr: address, status: bool, ctx:&mut TxContext){
		let sender = tx_context::sender(ctx);
		// Check owner 
		assert!(proof.owner == sender, EInvalidPermission);

		if (status == false){
			let (has, idx) = proof.whitelisted_addresses.index_of(&addr);
			if (has){
				proof.whitelisted_addresses.remove(idx);
			};
		}else{
			proof.whitelisted_addresses.push_back(addr);
		};

		event::emit(WhitelistUpdated{
			user: addr, 
			status: status
		})
	}

	public fun bind(proof: &mut Proof, addr: address, bytes: vector<u8>, ctx:&mut TxContext){
		// Check white list
		let sender = tx_context::sender(ctx);
		assert!(isWhitelisted(proof, sender), ENotWhiteListed);

		let data = UserData{
			data: bytes
		};

		vec_map::insert(&mut proof.user_data, addr, data);
		event::emit(Bound{
			addr: addr, 
			data: bytes 
		})
	}

	public fun rebind(proof:&mut Proof, oldAddr: address, newAddr: address, newData: vector<u8>, ctx:&mut TxContext){
		// Check white list
		let sender = tx_context::sender(ctx);
		assert!(isWhitelisted(proof, sender), ENotWhiteListed);

		event::emit(Rebound{
			oldAddr:oldAddr,
			oldData:proof.user_data[&oldAddr].data,
			newAddr:newAddr,
			newData:newData
		});

		// Del old bind 
		vec_map::remove(&mut proof.user_data, &oldAddr);

		// Rebind new data
		let data = UserData{
			data: newData 
		};		
		vec_map::insert(&mut proof.user_data, newAddr, data)
	}

	public fun getData(proof: &mut Proof, addr: address): vector<u8>{
 		assert!(vec_map::contains(&proof.user_data, &addr), ENoBindingDataForAddress);
		proof.user_data[&addr].data
	}
}
