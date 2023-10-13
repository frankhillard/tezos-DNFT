#import "../helpers/assert.mligo" "Assert"
#import "../bootstrap/bootstrap.mligo" "Bootstrap"
#import "../helpers/log.mligo" "Log"
#import "../helpers/collection.mligo" "Collection_helper"
#import "../../src/collection/main.mligo" "Collection"

let () = Log.describe("[Collection.approve_admin] test suite")

let bootstrap () = Bootstrap.boot_collection(0tez)

(* Successful ApproveAdmin *)
let test_success =
    let (accounts, collec) = bootstrap() in
    let (admin, other, _, _, _) = accounts in
    // let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Test.set_source admin in
    let () = Collection_helper.change_admin_success(other, 0tez, collec.contr) in
    let () = Collection_helper.assert_admin(collec.taddr, admin) in
    let () = Collection_helper.assert_requested_admin(collec.taddr, Some(other)) in
    let () = Test.set_source other in
    let () = Collection_helper.approve_admin_success(unit, 0tez, collec.contr) in
    let () = Collection_helper.assert_admin(collec.taddr, other) in
    Collection_helper.assert_requested_admin(collec.taddr, (None : address option))

(* Failing ApproveAdmin because amount not null *)
let test_failure_approve_admin_with_amount =
    let (accounts, collec) = bootstrap() in
    let (admin, other, _, _, _) = accounts in
    // let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Test.set_source admin in
    let () = Collection_helper.change_admin_success(other, 0tez, collec.contr) in
    let () = Collection_helper.assert_admin(collec.taddr, admin) in
    let () = Collection_helper.assert_requested_admin(collec.taddr, Some(other)) in
    let () = Test.set_source other in
    let r = Collection_helper.approve_admin(unit, 10tez, collec.contr) in
    Assert.string_failure r Collection.Errors.expects_0_tez

(* Failing ApproveAdmin because no request *)
let test_failure_approve_admin_without_request =
    let (accounts, collec) = bootstrap() in
    let (_admin, other, _, _, _) = accounts in
    // let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Test.set_source other in
    let r = Collection_helper.approve_admin(unit, 0tez, collec.contr) in
    Assert.string_failure r Collection.Errors.no_requested_admin

(* Failing ApproveAdmin because sender is not the requested_admin *)
let test_failure_approve_admin_with_sender_not_requested_admin =
    let (accounts, collec) = bootstrap() in
    let (admin, other, alice, _, _) = accounts in
    // let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Test.set_source admin in
    let () = Collection_helper.change_admin_success(other, 0tez, collec.contr) in
    let () = Collection_helper.assert_admin(collec.taddr, admin) in
    let () = Collection_helper.assert_requested_admin(collec.taddr, Some(other)) in
    let () = Test.set_source alice in
    let r = Collection_helper.approve_admin(unit, 0tez, collec.contr) in
    Assert.string_failure r Collection.Errors.sender_not_requested_admin
