#import "../../src/collection/main.mligo" "Collection"
#import "./assert.mligo" "Assert"

type taddr = (Collection.parameter, Collection.extended_storage) typed_address
type contr = Collection.parameter contract
type originated = {
    addr: address;
    taddr: taddr;
    contr: contr;
}

(* Some dummy values intended to be used as placeholders *)
let dummy_token_info =
    Map.literal [("",
      Bytes.pack "ipfs://QmbKq7QriWWU74NSq35sDSgUf24bYWTgpBq3Lea7A3d7jU")]

(* Base storage *)
let base_storage (admin : address) : Collection.extended_storage = {
    metadata = Big_map.literal([(("contents" : string), ("4d494e54454544" : bytes))]);
    ledger = (Big_map.empty : Collection.FA2.Ledger.t);
    token_metadata = (Big_map.empty : Collection.FA2.TokenMetadata.t);
    operators = (Big_map.empty : Collection.FA2.Operators.t);

    (* extension *)
    extension = {
        admin = admin;
        requested_admin = (None: address option);    
        asset_infos = (Big_map.empty : (nat, Collection.asset_info) big_map);
        use_whitelist = true;
        whitelist = (Big_map.empty : (address, bool) big_map);
        next_token_id = 0n;
    }
}

(* Originate a Collection contract with given init_storage storage *)
let originate (init_storage : Collection.extended_storage) =
    let (taddr, _, _) = Test.originate Collection.main init_storage 0mutez in
    let contr = Test.to_contract taddr in
    let addr = Tezos.address contr in
    {addr = addr; taddr = taddr; contr = contr}

(*
    Originate a Collection contract with given init_storage storage
    Use this one if you need access to views
*)
let originate_from_file (init_storage, balance : Collection.extended_storage * tez) =
    let f = "../../src/collection/main.mligo" in
    let v_mich = Test.run (fun (x:Collection.extended_storage) -> x) init_storage in
    let (addr, _, _) = Test.originate_from_file f "main" ["get_balance"; "is_whitelisted"; "is_authorized"; "use_whitelist"] v_mich balance in
    let taddr : taddr = Test.cast_address addr in
    let contr = Test.to_contract taddr in
    {addr = addr; taddr = taddr; contr = contr}

(* Call entry point of Collection contr contract *)
let call (p, contr : Collection.parameter * contr) =
    Test.transfer_to_contract contr p 0mutez

(* Call entry point of Collection contr contract with amount *)
let call_with_amount (p, amount_, contr : Collection.parameter * tez * contr) =
    Test.transfer_to_contract contr p amount_

(* Entry points call helpers *)
let authorize(p, amount_, contr : Collection.authorize_param * tez * contr) =
    call_with_amount(Authorize(p), amount_, contr)

let authorize_success(p, amount_, contr : Collection.authorize_param * tez * contr) =
    Assert.tx_success (authorize(p, amount_, contr))

let unauthorize(p, amount_, contr : Collection.unauthorize_param * tez * contr) =
    call_with_amount(Unauthorize(p), amount_, contr)

let unauthorize_success(p, amount_, contr : Collection.unauthorize_param * tez * contr) =
    Assert.tx_success (unauthorize(p, amount_, contr))

let use_whitelist(p, amount_, contr : Collection.use_whitelist_param * tez * contr) =
    call_with_amount(UseWhiteList(p), amount_, contr)

let use_whitelist_success(p, amount_, contr : Collection.use_whitelist_param * tez * contr) =
    Assert.tx_success (use_whitelist(p, amount_, contr))

let change_admin(p, amount_, contr : Collection.change_admin_param * tez * contr) =
    call_with_amount(ChangeAdmin(p), amount_, contr)

let change_admin_success(p, amount_, contr : Collection.change_admin_param * tez * contr) =
    Assert.tx_success (change_admin(p, amount_, contr))

let approve_admin(p, amount_, contr : unit * tez * contr) =
    call_with_amount(ApproveAdmin(p), amount_, contr)

let approve_admin_success(p, amount_, contr : unit * tez * contr) =
    Assert.tx_success (approve_admin(p, amount_, contr))


let premint (p, amount_, contr : Collection.premint_param * tez * contr) =
    call_with_amount(Premint(p), amount_, contr)

let change_collection_metadata (p, amount_, contr : (string, bytes) big_map * tez * contr) =
    call_with_amount(ChangeCollectionMetadata(p), amount_, contr)

let change_tokens_metadata (p, amount_, contr : Collection.change_token_metadata_param * tez * contr) =
    call_with_amount(ChangeTokensMetadata(p), amount_, contr)

let increase_reputation (p, amount_, contr : Collection.increase_reputation_param * tez * contr) =
    call_with_amount(IncreaseReputation(p), amount_, contr)

let update_operators (p, contr : Collection.FA2.update_operators * contr) =
    call(Update_operators(p), contr)

let update_tokens (p, amount_, contr: Collection.update_tokens_param * tez * contr) =
    call_with_amount(UpdateTokens(p), amount_, contr)

// let retrieve_locked_xtz(p, amount_, contr : unit * tez * contr) =
//     call_with_amount(RetrieveLockedXtz(p), amount_, contr)

(* Asserter helper for successful entry point calls *)
let premint_success (p, amount_, contr : Collection.premint_param * tez * contr) =
    Assert.tx_success (premint(p, amount_, contr))

let change_collection_metadata_success(p, amount_, contr : (string, bytes) big_map * tez * contr) =
    Assert.tx_success (change_collection_metadata(p, amount_, contr))

let change_tokens_metadata_success(p, amount_, contr : Collection.change_token_metadata_param * tez * contr) =
    Assert.tx_success (change_tokens_metadata(p, amount_, contr))

let increase_reputation_success(p, amount_, contr : Collection.increase_reputation_param * tez * contr) =
    Assert.tx_success (increase_reputation(p, amount_, contr))

let update_operators_success (p, contr : Collection.FA2.update_operators * contr) =
    Assert.tx_success (update_operators(p, contr))

let update_tokens_success (p, amount_, contr : Collection.update_tokens_param * tez * contr) =
    Assert.tx_success (update_tokens(p, amount_, contr))

// let retrieve_locked_xtz_success(p, amount_, contr : unit * tez * contr) =
//     Assert.tx_success (retrieve_locked_xtz(p, amount_, contr))

(* assert Collection contract at [taddr] have [owner] address, token id pair with [amount_] in its ledger *)
let assert_balance (taddr, owned, amount_ :
   taddr * (Collection.FA2.Ledger.owner * Collection.FA2.Ledger.token_id) * nat) =
    let s = Test.get_storage taddr in
    match Big_map.find_opt owned s.ledger with
        | Some tokens -> assert(tokens = amount_)
        | None -> Test.failwith("Big_map key should not be missing")

let assert_next_token_id (taddr, expected_next_token_id : taddr * nat) =
    let s = Test.get_storage taddr in
    assert(s.extension.next_token_id = expected_next_token_id)


(* assert Collection contract at [taddr] have [expected_admin] address as admin *)
let assert_admin (taddr, expected_admin : taddr * address) =
    let s = Test.get_storage taddr in
    assert(s.extension.admin = expected_admin)

(* assert Collection contract at [taddr] have [expected_requested_admin] address as requested_admin *)
let assert_requested_admin (taddr, expected_requested_admin : taddr * address option) =
    let s = Test.get_storage taddr in
    assert(s.extension.requested_admin = expected_requested_admin)

let assert_user_in_whitelist (taddr, user, expected_contained : taddr * address * bool) =
    let s = Test.get_storage taddr in
    let authorized = match Big_map.find_opt user s.extension.whitelist with
    | None -> false
    | Some auth -> auth
    in
    assert(authorized = expected_contained)

let assert_user_authorized (taddr, user, expected_authorized : taddr * address * bool) =
    let s = Test.get_storage taddr in
    if (s.extension.use_whitelist) then
        let authorized = match Big_map.find_opt user s.extension.whitelist with
        | None -> false
        | Some auth -> auth
        in
        assert(authorized = expected_authorized)
    else
        assert(expected_authorized = true)

let assert_whitelist_usage (taddr, expected_wl_usage : taddr * bool) =
    let s = Test.get_storage taddr in
    assert(s.extension.use_whitelist = expected_wl_usage)


(* assert Collection contract metadata *)
let assert_collection_metadata (taddr, key, expected_metadata : taddr * string * bytes) =
    let s = Test.get_storage taddr in
    match ((Big_map.find_opt key s.metadata) : bytes option) with
        | Some metas -> assert(metas = expected_metadata)
        | None -> Test.failwith("Big_map key should not be missing")

(* assert Collection contract token metadata *)
let assert_token_metadata (taddr, token_id, key, expected_contents : taddr * nat * string * bytes) =
    let s = Test.get_storage taddr in
    match Big_map.find_opt token_id s.token_metadata with
        | Some data -> (match Map.find_opt key data.token_info with
            | None -> Test.failwith("Big_map key should not be missing")
            | Some contents -> 
                // let v : nat = match Bytes.unpack contents with 
                // | Some v -> v  
                // | None -> Test.failwith("assert_token_metadata: bytes.unpack - not a number") 
                // in 
                // let () = Test.log v in
                assert(contents = expected_contents))
        | None -> Test.failwith("Big_map key should not be missing")

(* assert Collection contract XTZ balance *)
let assert_contract_balance (addr, amount_ :
   address * tez) =
    let s = Test.get_balance addr in
    // let () = Test.log(s) in
    assert(s = amount_)

(* premint a token with given params *)
let with_preminted
    (addr_source, contr, _admin_role :
     address * Collection.parameter contract * address) =
    let () = Test.set_source addr_source in
    premint_success
        ([{
            reputation = 0n
        }], 0mutez,
         contr)
