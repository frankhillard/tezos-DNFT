#import "../helpers/assert.mligo" "Assert"
#import "../bootstrap/bootstrap.mligo" "Bootstrap"
#import "../helpers/log.mligo" "Log"
#import "../helpers/collection.mligo" "Collection_helper"
#import "../../src/collection/main.mligo" "Collection"

let () = Log.describe("[Collection.change_admin] test suite")

let bootstrap () = Bootstrap.boot_collection(0tez)

(* Successful change_admin *)
let test_success =
    let (accounts, collec) = bootstrap() in
    let (admin, other, _, _, _) = accounts in
    // let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Test.set_source admin in
    let () = Collection_helper.change_admin_success(other, 0tez, collec.contr) in
    let () = Collection_helper.assert_admin(collec.taddr, admin) in
    Collection_helper.assert_requested_admin(collec.taddr, Some(other))

(* Failing change_admin because not admin *)
let test_failure_only_admin =
    let (accounts, collec) = bootstrap() in
    let (_admin, other, _, _, _) = accounts in
    // let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Test.set_source other in
    let r = Collection_helper.change_admin(other, 0tez, collec.contr) in
    Assert.string_failure r Collection.Errors.only_admin

(* Failing change_admin because amount not null *)
let test_failure_with_amount_not_null =
    let (accounts, collec) = bootstrap() in
    let (admin, other, _, _, _) = accounts in
    // let () = Collection_helper.with_preminted(admin, collec.contr,admin) in
    let () = Test.set_source admin in
    let r = Collection_helper.change_admin(other, 10tez, collec.contr) in
    Assert.string_failure r Collection.Errors.expects_0_tez