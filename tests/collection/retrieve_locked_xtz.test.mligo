#import "../helpers/assert.mligo" "Assert"
#import "../bootstrap/bootstrap.mligo" "Bootstrap"
#import "../helpers/log.mligo" "Log"
#import "../helpers/collection.mligo" "Collection_helper"
#import "../../src/collection/main.mligo" "Collection"

let () = Log.describe("[Collection.Retrieve_locked_xtz] test suite")

let initial_contract_balance = 2tez
let bootstrap () = Bootstrap.boot_collection(initial_contract_balance)

(* Successful Retrieve_locked_xtz with admin *)
let test_success_with_admin =
    let (accounts, collec) = bootstrap() in
    let (admin, creator, _alice, _, _) = accounts in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin, creator, True) in
    let s = Test.get_storage collec.taddr in
    let () = assert(s.extension.admin = admin) in
    let admin_before = Test.get_balance(admin) in 
    let () = Collection_helper.assert_contract_balance(collec.addr, initial_contract_balance) in
    let () = Test.set_source admin in
    let () = Collection_helper.retrieve_locked_xtz_success(unit, 0tez, collec.contr) in
    let () = Collection_helper.assert_contract_balance(collec.addr, 0mutez) in
    let admin_after = Test.get_balance(admin) in
    let admin_diff = Option.unopt(admin_after - admin_before) in
    // The admin pays an arbitrary cost of 1tez for calling the Retrieve_locked_xtz entrypoint
    let call_cost = 1tez in
    let expected_admin_diff = Option.unopt(initial_contract_balance - call_cost) in 
    assert(admin_diff = expected_admin_diff) 
    
(* Failing Retrieve_locked_xtz because not admin *)
let test_failure_retrieve_locked_xtz_only_admin =
    let (accounts, collec) = bootstrap() in
    let (admin, creator, alice, _, _) = accounts in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin, creator, True) in
    let () = Test.set_source alice in
    let r = Collection_helper.retrieve_locked_xtz(unit, 0tez, collec.contr) in
    Assert.string_failure r Collection.Errors.only_admin

(* Failing Retrieve_locked_xtz because Amount not null *)
let test_failure_retrieve_locked_xtz_with_amount =
    let (accounts, collec) = bootstrap() in
    let (admin, creator, _alice, _, _) = accounts in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin, creator, True) in
    let () = Test.set_source admin in
    let r = Collection_helper.retrieve_locked_xtz(unit, 10tez, collec.contr) in
    Assert.string_failure r Collection.Errors.expects_0_tez
