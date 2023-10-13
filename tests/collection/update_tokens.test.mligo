#import "../helpers/assert.mligo" "Assert"
#import "../bootstrap/bootstrap.mligo" "Bootstrap"
#import "../helpers/log.mligo" "Log"
#import "../helpers/collection.mligo" "Collection_helper"
#import "../../src/collection/main.mligo" "Collection"

let () = Log.describe("[Collection.Update_token] test suite")

let bootstrap () = Bootstrap.boot_collection(0tez)

(* Successful update of all available fields *)
let test_success_all =
    let (accounts, collec) = bootstrap() in
    let (admin, _, _, _, _) = accounts in
    let () = Test.set_source admin in
    let () = Collection_helper.authorize_success([admin], 0tez, collec.contr) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Test.set_source admin in
    let rep = Bytes.pack 10n in
    let new_metadata = Map.literal [("reputation", rep)] in
    let update_tokens_param = Map.literal [
        (1n, {
            new_metadata = Some(new_metadata);
        }); 
    ] in
    let () = Collection_helper.update_tokens_success(update_tokens_param, 0tez, collec.contr) in
    Collection_helper.assert_token_metadata(collec.taddr, 1n, "reputation", rep)

(* Successful update of some fields *)
let test_success_some =
    let (accounts, collec) = bootstrap() in
    let (admin, _, _, _, _) = accounts in
    let () = Test.set_source admin in
    let () = Collection_helper.authorize_success([admin], 0tez, collec.contr) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Test.set_source admin in
    let rep = Bytes.pack 42n in
    let _new_metadata = Map.literal [("reputation", rep)] in
    let update_tokens_param = Map.literal [
        (1n, {
            new_metadata = None;
        }); 
    ] in
    let () = Collection_helper.update_tokens_success(update_tokens_param, 0tez, collec.contr) in
    // verify it didn't change
    Collection_helper.assert_token_metadata(collec.taddr, 1n, "reputation", Bytes.pack 0n)

(* Successful update of some fields *)
let test_success_batch_some =
    let (accounts, collec) = bootstrap() in
    let (admin, _, _, _, _) = accounts in
    let () = Test.set_source admin in
    let () = Collection_helper.authorize_success([admin], 0tez, collec.contr) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Test.set_source admin in
    let rep = Bytes.pack 56n in
    let new_metadata = Map.literal [("reputation", rep)] in
    let update_tokens_param = Map.literal [
        (1n, {
            new_metadata = Some(new_metadata);
        });
        (2n, {
            new_metadata = None;
        }); 
    ] in
    let () = Collection_helper.update_tokens_success(update_tokens_param, 0tez, collec.contr) in
    let () = Collection_helper.assert_token_metadata(collec.taddr, 1n, "reputation", rep) in
    Collection_helper.assert_token_metadata(collec.taddr, 2n, "reputation", Bytes.pack 0n)


(* Failing because not admin *)
let test_failure_only_admin =
    let (accounts, collec) = bootstrap() in
    let (admin, other, _, _, _) = accounts in
    let () = Test.set_source admin in
    let () = Collection_helper.authorize_success([admin], 0tez, collec.contr) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Test.set_source other in
    let rep = Bytes.pack 101n in
    let new_metadata = Map.literal [("reputation", rep)] in
    let update_tokens_param = Map.literal [
        (1n, {
            new_metadata = Some(new_metadata);
        }); 
    ] in
    let r = Collection_helper.update_tokens(update_tokens_param, 0tez, collec.contr) in
    Assert.string_failure r Collection.Errors.only_admin

(* Failing because asset does not exists *)
let test_failure_missing_token_info =
    let (accounts, collec) = bootstrap() in
    let (admin, _other, _, _, _) = accounts in
    let () = Test.set_source admin in
    let () = Collection_helper.authorize_success([admin], 0tez, collec.contr) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Test.set_source admin in
    let rep = Bytes.pack 60n in
    let new_metadata = Map.literal [("reputation", rep)] in
    let update_tokens_param = Map.literal [
        (6n, {
            new_metadata = Some(new_metadata);
        }); 
    ] in
    let r = Collection_helper.update_tokens(update_tokens_param, 0tez, collec.contr) in
    Assert.string_failure r Collection.Errors.missing_token_info

(* Failing because amount not null *)
let test_failure_with_amount =
    let (accounts, collec) = bootstrap() in
    let (admin, _other, _, _, _) = accounts in
    let () = Test.set_source admin in
    let () = Collection_helper.authorize_success([admin], 0tez, collec.contr) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Test.set_source admin in
    let rep = Bytes.pack 15n in
    let new_metadata = Map.literal [("reputation", rep)] in
    let update_tokens_param = Map.literal [
        (1n, {
            new_metadata = Some(new_metadata);
        }); 
    ] in
    let r = Collection_helper.update_tokens(update_tokens_param, 10tez, collec.contr) in
    Assert.string_failure r Collection.Errors.expects_0_tez