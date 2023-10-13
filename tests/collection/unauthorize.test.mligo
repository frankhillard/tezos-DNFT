#import "../helpers/assert.mligo" "Assert"
#import "../bootstrap/bootstrap.mligo" "Bootstrap"
#import "../helpers/log.mligo" "Log"
#import "../helpers/collection.mligo" "Collection_helper"
#import "../../src/collection/main.mligo" "Collection"

let () = Log.describe("[Collection.unauthorize] test suite")

let bootstrap () = Bootstrap.boot_collection(0tez)

(* Successful unauthorize *)
let test_success =
    let (accounts, collec) = bootstrap() in
    let (admin, other, _, _, _) = accounts in
    // let () = Collection_helper.with_preminted(admin, collec.contr,admin) in
    let () = Test.set_source admin in
    let () = Collection_helper.authorize_success([other], 0tez, collec.contr) in
    let () = Collection_helper.assert_user_in_whitelist(collec.taddr, other, true) in
    let () = Collection_helper.unauthorize_success([other], 0tez, collec.contr) in
    Collection_helper.assert_user_in_whitelist(collec.taddr, other, false)

let test_success_multiple =
    let (accounts, collec) = bootstrap() in
    let (admin, other, alice, _, _) = accounts in
    // let () = Collection_helper.with_preminted(admin, collec.contr,admin) in
    let () = Test.set_source admin in
    let () = Collection_helper.authorize_success([other; alice], 0tez, collec.contr) in
    let () = Collection_helper.assert_user_in_whitelist(collec.taddr, other, true) in
    let () = Collection_helper.assert_user_in_whitelist(collec.taddr, alice, true) in
    let () = Collection_helper.unauthorize_success([other; alice], 0tez, collec.contr) in
    let () = Collection_helper.assert_user_in_whitelist(collec.taddr, other, false) in
    Collection_helper.assert_user_in_whitelist(collec.taddr, alice, false)

(* Failing unauthorize because not admin *)
let test_failure_only_admin =
    let (accounts, collec) = bootstrap() in
    let (admin, other, _, _, _) = accounts in
    // let () = Collection_helper.with_preminted(admin, collec.contr,admin) in
    let () = Test.set_source admin in
    let () = Collection_helper.authorize_success([other], 0tez, collec.contr) in
    let () = Collection_helper.assert_user_in_whitelist(collec.taddr, other, true) in
    let () = Test.set_source other in
    let r = Collection_helper.unauthorize([other], 0tez, collec.contr) in
    Assert.string_failure r Collection.Errors.only_admin

(* Failing unauthorize because amount not null *)
let test_failure_with_amount_not_null =
    let (accounts, collec) = bootstrap() in
    let (admin, other, _, _, _) = accounts in
    // let () = Collection_helper.with_preminted(admin, collec.contr,admin) in
    let () = Test.set_source admin in
    let () = Collection_helper.authorize_success([other], 0tez, collec.contr) in
    let () = Collection_helper.assert_user_in_whitelist(collec.taddr, other, true) in
    let () = Test.set_source admin in
    let r = Collection_helper.unauthorize([other], 10tez, collec.contr) in
    Assert.string_failure r Collection.Errors.expects_0_tez