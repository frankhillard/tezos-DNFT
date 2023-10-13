#import "../helpers/assert.mligo" "Assert"
#import "../bootstrap/bootstrap.mligo" "Bootstrap"
#import "../helpers/log.mligo" "Log"
#import "../helpers/collection.mligo" "Collection_helper"
#import "../../src/collection/main.mligo" "Collection"

let () = Log.describe("[Collection.premint] test suite")

let bootstrap () = Bootstrap.boot_collection(0tez)

(* Successful premint with XTZ as currency *)
let test_premint_success =
    let (accounts, collec) = bootstrap() in
    let (admin, other, _, _, _) = accounts in
    let () = Test.set_source admin in
    let () = Collection_helper.authorize_success([other], 0tez, collec.contr) in
    let () = Test.set_source other in
    let () = Collection_helper.premint_success([{
        reputation = 100n;
        }], 0tez, collec.contr)
    in
    let () = Collection_helper.assert_balance(collec.taddr, (other, 0n), 1n) in
    let expected_token_metadata : bytes = Bytes.pack 0n in
    let () = Collection_helper.assert_token_metadata(collec.taddr, 0n, "reputation", expected_token_metadata) in
    Collection_helper.assert_next_token_id(collec.taddr, 1n)
    

(* Successful premint with multiple assets *)
let test_success_batch =
    let (accounts, collec) = bootstrap() in
    let (admin, other, _, _, _) = accounts in
    let () = Test.set_source admin in
    let () = Collection_helper.authorize_success([other], 0tez, collec.contr) in
    let () = Test.set_source other in
    let () = Collection_helper.premint_success([{
        reputation = 100n;
        }; {
        reputation = 100n;
        }], 0tez, collec.contr)
    in
    let () = Collection_helper.assert_balance(collec.taddr, (other, 0n), 1n) in
    let () = Collection_helper.assert_balance(collec.taddr, (other, 1n), 1n) in
    let expected_token_metadata : bytes = Bytes.pack 0n in
    let () = Collection_helper.assert_token_metadata(collec.taddr, 0n, "reputation", expected_token_metadata) in
    let () = Collection_helper.assert_token_metadata(collec.taddr, 1n, "reputation", expected_token_metadata) in
    Collection_helper.assert_next_token_id(collec.taddr, 2n)

(* Successful premint with XTZ as currency *)
let test_premint_success_with_disabled_whitelist =
    let (accounts, collec) = bootstrap() in
    let (admin, other, _, _, _) = accounts in
    let () = Test.set_source admin in
    let () = Collection_helper.use_whitelist_success(false, 0tez, collec.contr) in
    let () = Test.set_source other in
    let () = Collection_helper.premint_success([{
        reputation = 100n;
        }], 0tez, collec.contr)
    in
    let () = Collection_helper.assert_balance(collec.taddr, (other, 0n), 1n) in
    let expected_token_metadata : bytes = Bytes.pack 0n in
    let () = Collection_helper.assert_token_metadata(collec.taddr, 0n, "reputation", expected_token_metadata) in
    Collection_helper.assert_next_token_id(collec.taddr, 1n)

(* Failure because amount given *)
let test_failure_premint_with_amount =
    let (accounts, collec) = bootstrap() in
    let (admin, other, _, _, _) = accounts in
    let () = Test.set_source admin in
    let () = Collection_helper.authorize_success([other], 0tez, collec.contr) in
    let () = Test.set_source other in
    let r = Collection_helper.premint([{
        reputation = 100n;
        }], 10tez, collec.contr)
    in
    Assert.string_failure r Collection.Errors.expects_0_tez

(* Failure because caller not authorized *)
let test_failure_premint_with_unauthorized_user =
    let (accounts, collec) = bootstrap() in
    let (_admin, other, _, _, _) = accounts in
    let () = Test.set_source other in
    let r = Collection_helper.premint([{
        reputation = 100n;
        }], 0tez, collec.contr)
    in
    Assert.string_failure r Collection.Errors.not_authorized

