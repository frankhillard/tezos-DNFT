#import "../helpers/assert.mligo" "Assert"
#import "../bootstrap/bootstrap.mligo" "Bootstrap"
#import "../helpers/log.mligo" "Log"
#import "../helpers/collection.mligo" "Collection_helper"
#import "../../src/collection/main.mligo" "Collection"

let () = Log.describe("[Collection.increase_reputation] test suite")

let bootstrap () = Bootstrap.boot_collection(0tez)

(* Successful IncreaseReputation *)
let test_success =
    let (accounts, collec) = bootstrap() in
    let (admin, _, _, _, _) = accounts in
    let () = Test.set_source admin in
    let () = Collection_helper.authorize_success([admin], 0tez, collec.contr) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Test.set_source admin in

    let extra_rep_amounts = Map.literal [(1n, 10n); (2n, 20n)] in
    let () = Collection_helper.increase_reputation_success(extra_rep_amounts, 0tez, collec.contr) in
    let () = Collection_helper.assert_token_metadata(collec.taddr, 1n, "reputation", Bytes.pack 10n) in
    let () = Collection_helper.assert_token_metadata(collec.taddr, 2n, "reputation", Bytes.pack 20n) in

    //let extra_rep_amounts = Map.literal [(1n, 10n); (2n, 20n)] in
    let () = Collection_helper.increase_reputation_success(extra_rep_amounts, 0tez, collec.contr) in
    let () = Collection_helper.assert_token_metadata(collec.taddr, 1n, "reputation", Bytes.pack 20n) in
    let () = Collection_helper.assert_token_metadata(collec.taddr, 2n, "reputation", Bytes.pack 40n) in

    (* verifies the other token is unchanged *)
    Collection_helper.assert_token_metadata(
        collec.taddr,
        0n,
        "reputation",
        Bytes.pack 0n
    )

(* Failing IncreaseReputation because not admin *)
let test_failure_only_admin =
    let (accounts, collec) = bootstrap() in
    let (admin, other, _, _, _) = accounts in
    let () = Test.set_source admin in
    let () = Collection_helper.authorize_success([admin], 0tez, collec.contr) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Test.set_source other in
    let extra_rep_amounts = Map.literal [(1n, 10n); (2n, 20n)] in
    let r = Collection_helper.increase_reputation(extra_rep_amounts, 0tez, collec.contr) in
    Assert.string_failure r Collection.Errors.only_admin

(* Failing IncreaseReputation because asset does not exists *)
let test_failure_missing_token_info =
    let (accounts, collec) = bootstrap() in
    let (admin, _, _, _, _) = accounts in
    let () = Test.set_source admin in
    let () = Collection_helper.authorize_success([admin], 0tez, collec.contr) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Test.set_source admin in
    let extra_rep_amounts = Map.literal [(1n, 10n); (4n, 20n)] in
    let r = Collection_helper.increase_reputation(extra_rep_amounts, 0tez, collec.contr) in
    Assert.string_failure r Collection.Errors.missing_token_info

(* Failing IncreaseReputation because amount not null *)
let test_failure_change_token_metadata_with_amount =
    let (accounts, collec) = bootstrap() in
    let (admin, _, _, _, _) = accounts in
    let () = Test.set_source admin in
    let () = Collection_helper.authorize_success([admin], 0tez, collec.contr) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Test.set_source admin in
    let extra_rep_amounts = Map.literal [(1n, 10n); (4n, 20n)] in
    let r = Collection_helper.increase_reputation(extra_rep_amounts, 10tez, collec.contr) in
    Assert.string_failure r Collection.Errors.expects_0_tez
