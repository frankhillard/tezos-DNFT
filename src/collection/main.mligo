#import "ligo-extendable-fa2/lib/multi_asset/fa2.mligo" "FA2"
#import "./constants.mligo" "Constants"
#import "./errors.mligo" "Errors"
// #import "./total_supply.mligo" "TotalSupply"
// #import "../shared/common.mligo" "Common"

type storage = FA2.storage

type asset_info = {
    reputation : nat;
}

type extension = {
    admin: address;
    requested_admin : address option;    
    asset_infos : (nat, asset_info) big_map;
    use_whitelist : bool;
    whitelist: (address, bool) big_map;
    next_token_id: nat;
}

type extended_storage = extension storage

let authorize_admin (s:extended_storage): unit =
    let sender_ = Tezos.get_sender() in
    assert_with_error (sender_ = s.extension.admin) Errors.only_admin

let is_whitelist_authorized (p, s : address * extended_storage) : bool =
    if s.extension.use_whitelist then 
        match Big_map.find_opt p s.extension.whitelist with
        | None -> false
        | Some auth -> auth
    else 
        True

type premint_asset_info = {
    reputation: nat;
}

type premint_param = premint_asset_info list

type tokenmetadata_param = [@layout:comb] {
    tokenid : nat;
    ipfsuri : bytes
}

let premint (param: premint_param) (s: extended_storage) : operation list * extended_storage =
    let _check_amount_zero : unit = assert_with_error (Tezos.get_amount() = 0tez) Errors.expects_0_tez in
    let sender_ = Tezos.get_sender() in
    let authorized = is_whitelist_authorized(sender_, s) in
    let _check_authorized : unit = assert_with_error (authorized = true) Errors.not_authorized in
    
    let create_asset(acc, _elt: (FA2.Ledger.t * FA2.TokenMetadata.t * extension) * premint_asset_info) : (FA2.Ledger.t * FA2.TokenMetadata.t * extension) =
        let default_metadata : (string, bytes) map = Map.literal [("reputation",Bytes.pack 0n)] in
        
        // let info_token_metadata = { reputation=0n; royalties={ decimals=3; shares=Map.literal[(s.extension.admin, 1n)] }} in
        // let default_metadata : (string, bytes) map = Map.literal [
        //     ("", Bytes.pack "tezos-storage:contents");
        //     ("contents", Bytes.pack info_token_metadata)
        //     // ("reputation",Bytes.pack 0n);
        //     // ("royalties", Bytes.pack ({
        //     //     decimals=2n;
        //     //     shares=Map.literal[(s.extension.admin, 1n)]
        //     // }))
        // ] in
                
        let (ledger, meta, ext) = acc in
        let current_token_id = ext.next_token_id in
        (
            FA2.Ledger.increase_token_amount_for_user ledger sender_ current_token_id 1n,
            Big_map.update current_token_id (Some { token_id = current_token_id; token_info = default_metadata }) meta,
            { ext with
                next_token_id = current_token_id + 1n;
                asset_infos = Big_map.update current_token_id (Some { reputation=0n; }) ext.asset_infos;            
            }
        )
    in
    let (new_ledger, new_token_metadata, new_extension) : (FA2.Ledger.t * FA2.TokenMetadata.t * extension) =
        List.fold create_asset param (s.ledger, s.token_metadata, s.extension) in
    (Constants.no_operation, { s with ledger = new_ledger; token_metadata = new_token_metadata; extension = new_extension })


let change_metadata (new_metadata: (string, bytes) big_map) (s: extended_storage) : operation list * extended_storage =
    let _check_amount_zero : unit = assert_with_error (Tezos.get_amount() = 0tez) Errors.expects_0_tez in
    let newMetadataMap = new_metadata in
    (Constants.no_operation, { s with metadata=newMetadataMap; })

let update_token_metadata (id: nat) (metadata: (string, bytes) map) (s: extended_storage) : extended_storage =
    match Big_map.find_opt id s.token_metadata with
        None -> failwith Errors.missing_token_info
        | Some _ -> { s with
            token_metadata = Big_map.update id (Some({
                token_id = id;
                token_info = metadata
            })) s.token_metadata }

let increase_reputation (id: nat) (amount: nat) (s: extended_storage) : extended_storage =
    match Big_map.find_opt id s.token_metadata with
        None -> failwith Errors.missing_token_info
        | Some tmd ->
            let ti : (string,bytes) map = tmd.token_info in
            let new_token_metadata = match Map.find_opt "reputation" ti with
                | None -> failwith Errors.missing_reputation_field
                | Some rep -> 
                    // let rep_bytes : bytes = rep in
                    let rep_nat_opt : nat option = Bytes.unpack rep in
                    let new_rep_nat = match rep_nat_opt with
                        | None -> failwith Errors.missing_reputation_field
                        | Some rep_nat -> rep_nat + amount
                        in
                        Big_map.update id (Some({
                            token_id = id;
                            token_info = Map.update "reputation" (Some(Bytes.pack new_rep_nat)) ti
                        })) s.token_metadata 
            in
            { s with token_metadata = new_token_metadata}

// type info_contents = { 
//     reputation: nat; 
//     royalties: { 
//         decimals: nat; 
//         shares: (address, nat) map
//     }
// }

// let increase_reputation (id: nat) (amount: nat) (s: extended_storage) : extended_storage =
//     match Big_map.find_opt id s.token_metadata with
//         None -> failwith Errors.missing_token_info
//         | Some tmd ->
//             let ti : (string,bytes) map = tmd.token_info in
//             let new_token_metadata = match Map.find_opt "contents" ti with
//                 | None -> failwith "Missing contents field"
//                 | Some contents ->
//                     let contents_opt : info_contents option = Bytes.unpack contents in
//                     let contents = match contents_opt with
//                         | None -> failwith "Cannot decode contents"
//                         | Some c -> c 
//                     in
//                     // let { reputation; _royalties } = contents in
//                     let new_info_contents = { contents with reputation=contents.reputation + amount } in
//                     Big_map.update id (Some({
//                             token_id = id;
//                             token_info = Map.update "contents" (Some(Bytes.pack new_info_contents)) ti
//                         })) s.token_metadata 

//             in
//             { s with token_metadata = new_token_metadata}

type increase_reputation_param = (nat, nat) map

let increase_token_reputation (param: increase_reputation_param) (s: extended_storage) : operation list * extended_storage =
    let _check_amount_zero : unit = assert_with_error (Tezos.get_amount() = 0tez) Errors.expects_0_tez in
    let apply_increase_reputation (acc, elt : extended_storage * (FA2.Storage.token_id * nat)) : extended_storage =
        let (tokenID, amount) = elt in
        increase_reputation tokenID amount acc
    in
    let new_extended_storage = Map.fold apply_increase_reputation param s in
    (Constants.no_operation, new_extended_storage)

type change_token_metadata_param = (nat, (string, bytes) map) map

let change_tokens_metadata (param : change_token_metadata_param)(s: extended_storage) : operation list * extended_storage =
    let _check_amount_zero : unit = assert_with_error (Tezos.get_amount() = 0tez) Errors.expects_0_tez in
    let apply_token_change (acc, elt : extended_storage * (FA2.Storage.token_id * (string, bytes) map)) : extended_storage =
        let (tokenID, newMetadata) = elt in
        update_token_metadata tokenID newMetadata acc
    in
    let new_extended_storage = Map.fold apply_token_change param s in
    (Constants.no_operation, new_extended_storage)


// let retrieve_locked_xtz (_param : unit)(s: extended_storage) : operation list * extended_storage =
//     let _check_amount_zero : unit = assert_with_error (Tezos.get_amount() = 0tez) Errors.expects_0_tez in
//     let destination : unit contract = match (Tezos.get_contract_opt s.extension.admin : unit contract option) with
//         | None -> failwith Errors.unknown_admin
//         | Some contr -> contr
//     in
//     let amt = Tezos.get_balance() in
//     let op : operation = Tezos.transaction unit amt destination in
//     ([op], s)


type update_token_params = [@layout:comb] {
    new_metadata: (string, bytes) map option;
}

let update_token (id: nat)(p: update_token_params) (s: extended_storage) : extended_storage =
    let { new_metadata } = p in
    let _check_amount_zero : unit = assert_with_error (Tezos.get_amount() = 0tez) Errors.expects_0_tez in
    let s = match new_metadata with
        None -> s
        | Some metadata -> update_token_metadata id metadata s
    in
    // let s = match new_is_mintable with
    //     None -> s
    //     | Some is_mintable -> update_is_mintable id is_mintable s
    // in
    s


type update_tokens_param = (nat, update_token_params) map

let update_tokens (param : update_tokens_param) (s: extended_storage) : operation list * extended_storage =
    let _check_amount_zero : unit = assert_with_error (Tezos.get_amount() = 0tez) Errors.expects_0_tez in
    let apply_token_change (acc, elt : extended_storage * (FA2.Storage.token_id * update_token_params)) : extended_storage =
        let (token_id, changes) = elt in
        update_token token_id changes acc
    in
    let new_extended_storage = Map.fold apply_token_change param s in
    (Constants.no_operation, new_extended_storage)




type authorize_param = address list

type unauthorize_param = address list

let authorize (param : authorize_param) (s : extended_storage) : operation list * extended_storage =
    let _check_amount_zero : unit = assert_with_error (Tezos.get_amount() = 0tez) Errors.expects_0_tez in
    let add_address (acc, elt : (address, bool) big_map * address) : (address, bool) big_map =
        match Big_map.find_opt elt acc with
        | None -> Big_map.add elt true acc
        | Some _auth -> Big_map.update elt (Some(true)) acc
    in
    let modified_wl = List.fold add_address param s.extension.whitelist in
    let new_extended_storage = { s.extension with whitelist = modified_wl } in
    (Constants.no_operation, {s with extension = new_extended_storage })

let unauthorize (param : unauthorize_param) (s : extended_storage) : operation list * extended_storage =
    let _check_amount_zero : unit = assert_with_error (Tezos.get_amount() = 0tez) Errors.expects_0_tez in
    let remove_address (acc, elt : (address, bool) big_map * address) : (address, bool) big_map =
        match Big_map.find_opt elt acc with
        | None -> acc
        | Some _auth -> Big_map.remove elt acc
    in
    let modified_wl = List.fold remove_address param s.extension.whitelist in
    let new_extended_storage = { s.extension with whitelist = modified_wl } in
    (Constants.no_operation, {s with extension = new_extended_storage })

type use_whitelist_param = bool

let switchWhiteListUsage (param : use_whitelist_param) (s : extended_storage) : operation list * extended_storage =
    let _check_amount_zero : unit = assert_with_error (Tezos.get_amount() = 0tez) Errors.expects_0_tez in
    let new_extended_storage = { s.extension with use_whitelist = param } in
    (Constants.no_operation, {s with extension = new_extended_storage })

type change_admin_param = address

let changeAdmin (param : change_admin_param) (s : extended_storage) : operation list * extended_storage =
    let _check_amount_zero : unit = assert_with_error (Tezos.get_amount() = 0tez) Errors.expects_0_tez in
    let new_extended_storage = { s.extension with requested_admin = Some(param) } in
    (Constants.no_operation, {s with extension = new_extended_storage})

let approveAdmin (_p : unit)(s : extended_storage) : operation list * extended_storage =
    let _check_amount_zero : unit = assert_with_error (Tezos.get_amount() = 0tez) Errors.expects_0_tez in
    let requested_admin = match s.extension.requested_admin with
    | None -> failwith(Errors.no_requested_admin)
    | Some addr -> addr
    in
    let _check_sender_requested_admin : unit = assert_with_error (Tezos.get_sender() = requested_admin) Errors.sender_not_requested_admin in
    let new_extended_storage = { s.extension with 
        admin = requested_admin; 
        requested_admin = (None : address option); 
    } in
    (Constants.no_operation, {s with extension = new_extended_storage})

type parameter = [@layout:comb]
    | Transfer of FA2.transfer
    | Balance_of of FA2.balance_of
    | Update_operators of FA2.update_operators
    | Premint of premint_param
    | ChangeCollectionMetadata of (string, bytes) big_map
    | ChangeTokensMetadata of change_token_metadata_param
    // | RetrieveLockedXtz of unit
    | UpdateTokens of update_tokens_param
    | UseWhiteList of use_whitelist_param
    | Authorize of authorize_param
    | Unauthorize of unauthorize_param
    | ChangeAdmin of change_admin_param
    | ApproveAdmin of unit
    | IncreaseReputation of increase_reputation_param



let main (p, s : parameter * extended_storage) : operation list * extended_storage =
    match p with
        Transfer                    p -> FA2.transfer p s
        | Balance_of                p -> FA2.balance_of p s
        | Update_operators          p -> FA2.update_ops p s
        | Premint                   p -> premint p s
        | ChangeCollectionMetadata  p -> let _ = authorize_admin s in
                                       change_metadata p s
        | ChangeTokensMetadata      p -> let _ = authorize_admin s in
                                       change_tokens_metadata p s
        // | RetrieveLockedXtz        p -> let _ = authorize_admin s in
        //                                retrieve_locked_xtz p s
        | UpdateTokens              p -> let _ = authorize_admin s in
                                       update_tokens p s
        | UseWhiteList              p -> let _ = authorize_admin s in
                                       switchWhiteListUsage p s
        | Authorize                 p -> let _ = authorize_admin s in
                                        authorize p s
        | Unauthorize               p -> let _ = authorize_admin s in
                                        unauthorize p s
        | ChangeAdmin               p -> let _ = authorize_admin s in
                                        changeAdmin p s
        | ApproveAdmin              p -> approveAdmin p s
        | IncreaseReputation        p -> let _ = authorize_admin s in
                                        increase_token_reputation p s


let assert_token_exist (s:extended_storage) (token_id : nat) : unit  =
    let _ = Option.unopt_with_error (Big_map.find_opt token_id s.token_metadata)
      Errors.undefined_token in
    ()

let get_balance (s:extended_storage) (owner:address) (token_id:nat) : nat =
    let () = assert_token_exist s token_id in
    FA2.Ledger.get_for_user s.ledger owner token_id

[@view] let get_balance (p, s : (address * nat) * extended_storage) : nat =
    let (owner, token_id) = p in
    get_balance s owner token_id


[@view]
let is_whitelisted (p, s : address * extended_storage) : bool =
    match Big_map.find_opt p s.extension.whitelist with
    | None -> false
    | Some auth -> auth

[@view]
let is_authorized (p, s : address * extended_storage) : bool =
    is_whitelist_authorized(p, s)

[@view]
let use_whitelist (_, s : unit * extended_storage) : bool =
    s.extension.use_whitelist