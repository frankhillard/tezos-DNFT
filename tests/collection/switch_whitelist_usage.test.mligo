#import "../helpers/assert.mligo" "Assert"
#import "../bootstrap/bootstrap.mligo" "Bootstrap"
#import "../helpers/log.mligo" "Log"
#import "../helpers/collection.mligo" "Collection_helper"
#import "../../src/collection/main.mligo" "Collection"

let () = Log.describe("[Collection.use_whitelist] test suite")

let bootstrap () = Bootstrap.boot_collection(0tez)

(* Successful use_whitelist *)
let test_success =
    let (accounts, collec) = bootstrap() in
    let (admin, _other, _, _, _) = accounts in
    // let () = Collection_helper.with_preminted(admin, collec.contr,admin) in
    let () = Collection_helper.assert_whitelist_usage(collec.taddr, true) in
    let () = Test.set_source admin in
    let () = Collection_helper.use_whitelist_success(false, 0tez, collec.contr) in
    Collection_helper.assert_whitelist_usage(collec.taddr, false)

(* Failing use_whitelist because not admin *)
let test_failure_only_admin =
    let (accounts, collec) = bootstrap() in
    let (_admin, other, _, _, _) = accounts in
    // let () = Collection_helper.with_preminted(admin, collec.contr,admin) in
    let () = Collection_helper.assert_whitelist_usage(collec.taddr, true) in
    let () = Test.set_source other in
    let r = Collection_helper.use_whitelist(false, 0tez, collec.contr) in
    Assert.string_failure r Collection.Errors.only_admin

(* Failing use_whitelist because amount not null *)
let test_failure_with_amount_not_null =
    let (accounts, collec) = bootstrap() in
    let (admin, _other, _, _, _) = accounts in
    // let () = Collection_helper.with_preminted(admin, collec.contr,admin) in
    let () = Collection_helper.assert_whitelist_usage(collec.taddr, true) in
    let () = Test.set_source admin in
    let r = Collection_helper.use_whitelist(false, 10tez, collec.contr) in
    Assert.string_failure r Collection.Errors.expects_0_tez