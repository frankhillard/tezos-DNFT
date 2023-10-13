#import "./errors.mligo" "Errors"

type token_id = nat

type amount_ = nat

type distribution =
  {total : nat; available : nat; reserved : nat}

type t = (token_id, distribution) big_map

let get_distribution_for_token_id
  (totalsupplies : t)
  (token_id : token_id) : distribution =
  match Big_map.find_opt token_id totalsupplies with
    Some (a) -> a
  | None ->
      (failwith (Errors.missing_distribution)
       : distribution)

let set_distribution_for_token_id
  (totalsupplies : t)
  (token_id : token_id)
  (distrib : distribution) : t =
  Big_map.update token_id (Some distrib) totalsupplies

let decrease_available_for_token_id
  (totalsupplies : t)
  (token_id : token_id)
  (amount_minted : nat) : t =
  let distrib =
    get_distribution_for_token_id totalsupplies token_id in
  let _check_limit_reached : unit =
    assert_with_error
      (distrib.available >= amount_minted)
      Errors.insufficient_available_editions in
  let new_distrib =
    {distrib with
      available = abs (distrib.available - amount_minted)} in
  set_distribution_for_token_id
    totalsupplies
    token_id
    new_distrib

let increase_available_for_token_id
  (totalsupplies : t)
  (token_id : token_id)
  (amount_to_be_minted : nat) : t =
  let distrib = get_distribution_for_token_id totalsupplies token_id in
  let new_distrib = { distrib with
      available = distrib.available + amount_to_be_minted 
  } in
  set_distribution_for_token_id
    totalsupplies
    token_id
    new_distrib

let decrease_reserved_for_token_id
  (totalsupplies : t)
  (token_id : token_id)
  (amount_minted : nat) : t =
  let distrib =
    get_distribution_for_token_id totalsupplies token_id in
  let _check_limit_reached : unit =
    assert_with_error
      (distrib.reserved >= amount_minted)
      Errors.insufficient_reserved_editions in
  let new_distrib =
    {distrib with
      reserved = abs (distrib.reserved - amount_minted)} in
  set_distribution_for_token_id
    totalsupplies
    token_id
    new_distrib
