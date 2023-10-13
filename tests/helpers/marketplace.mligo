#import "../../src/marketplace/main.mligo" "Marketplace"
#import "./assert.mligo" "Assert"

(* Some types for readability *)
type taddr = (Marketplace.parameter, Marketplace.storage) typed_address
type contr = Marketplace.parameter contract
type originated = {
    addr: address;
    taddr: taddr;
    contr: contr;
}

(* Base Marketplace storage *)
let base_storage : Marketplace.storage = {
    next_sell_id = 0n;
    active_proposals = (Set.empty : nat set);
    sell_proposals = (Big_map.empty : (nat, Marketplace.Storage.sell_proposal) big_map);
}

(* Originate a Marketplace contract with given init_storage storage *)
let originate (init_storage : Marketplace.storage) =
    let (taddr, _, _) = Test.originate Marketplace.main init_storage 0mutez in
    let contr = Test.to_contract taddr in
    let addr = Tezos.address contr in
    {addr = addr; taddr = taddr; contr = contr}

(* Call entry point of Marketplace contr contract *)
let call (p, contr : Marketplace.parameter * contr) =
    Test.transfer_to_contract contr p 0mutez

(* Call entry point of Marketplace contr contract with amount *)
let call_with_amount (p, amount_, contr : Marketplace.parameter * tez * contr) =
    Test.transfer_to_contract contr p amount_

(* Entry points call helpers *)
let sell (p, contr : Marketplace.Parameter.sell_proposal_param * contr) =
    call(Sell(p), contr)

let buy (p, amount_, contr : Marketplace.Parameter.buy_param * tez * contr) =
    call_with_amount(Buy(p), amount_, contr)

(* Asserter helper for successful entry point calls *)
let sell_success (p, contr : Marketplace.Parameter.sell_proposal_param * contr) =
    Assert.tx_success (sell(p, contr))

let buy_success (p, amount_, contr : Marketplace.Parameter.buy_param * tez * contr) =
    Assert.tx_success (buy(p, amount_, contr))
