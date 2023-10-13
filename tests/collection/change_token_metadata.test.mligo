#import "../helpers/assert.mligo" "Assert"
#import "../bootstrap/bootstrap.mligo" "Bootstrap"
#import "../helpers/log.mligo" "Log"
#import "../helpers/collection.mligo" "Collection_helper"
#import "../../src/collection/main.mligo" "Collection"

let () = Log.describe("[Collection.Change_token_metadata] test suite")

let bootstrap () = Bootstrap.boot_collection(0tez)

(* Successful ChangeTokenMetadata *)
let test_success =
    let (accounts, collec) = bootstrap() in
    let (admin, _, _, _, _) = accounts in
    let () = Test.set_source admin in
    let () = Collection_helper.authorize_success([admin], 0tez, collec.contr) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Test.set_source admin in

    let new_metadata_1 = Map.literal [("reputation", Bytes.pack 10n); ("whatever", 0x45)] in
    let new_metadata_2 = Map.literal [("reputation", Bytes.pack 20n); ("whatever", 0x46)] in
    let new_token_metadatas = Map.literal [(1n, new_metadata_1); (2n, new_metadata_2)] in
    let () = Collection_helper.change_tokens_metadata_success(new_token_metadatas, 0tez, collec.contr) in
    let () = Collection_helper.assert_token_metadata(collec.taddr, 1n, "reputation", Bytes.pack 10n) in
    let () = Collection_helper.assert_token_metadata(collec.taddr, 1n, "whatever", 0x45) in
    let () = Collection_helper.assert_token_metadata(collec.taddr, 2n, "reputation", Bytes.pack 20n) in
    let () = Collection_helper.assert_token_metadata(collec.taddr, 2n, "whatever", 0x46) in
    (* verifies the other token is unchanged *)
    Collection_helper.assert_token_metadata(
        collec.taddr,
        0n,
        "reputation",
        Bytes.pack 0n
    )

(* Failing ChangeTokenMetadata because not admin *)
let test_failure_only_admin =
    let (accounts, collec) = bootstrap() in
    let (admin, other, _, _, _) = accounts in
    let () = Test.set_source admin in
    let () = Collection_helper.authorize_success([admin], 0tez, collec.contr) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Test.set_source other in
    let new_metadata = Map.literal [("whatever", 0x45)] in
    let new_tokens_metadata = Map.literal [(1n, new_metadata)] in
    let r = Collection_helper.change_tokens_metadata(new_tokens_metadata, 0tez, collec.contr) in
    Assert.string_failure r Collection.Errors.only_admin

(* Failing ChangeTokenMetadata because asset does not exists *)
let test_failure_missing_token_info =
    let (accounts, collec) = bootstrap() in
    let (admin, _, _, _, _) = accounts in
    let () = Test.set_source admin in
    let () = Collection_helper.authorize_success([admin], 0tez, collec.contr) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Test.set_source admin in
    let new_metadata = Map.literal [("whatever", 0x45)] in
    let new_tokens_metadata = Map.literal [(4n, new_metadata)] in
    let r = Collection_helper.change_tokens_metadata(new_tokens_metadata, 0tez, collec.contr) in
    Assert.string_failure r Collection.Errors.missing_token_info

(* Failing ChangeTokenMetadata because amount not null *)
let test_failure_change_token_metadata_with_amount =
    let (accounts, collec) = bootstrap() in
    let (admin, _, _, _, _) = accounts in
    let () = Test.set_source admin in
    let () = Collection_helper.authorize_success([admin], 0tez, collec.contr) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Collection_helper.with_preminted(admin, collec.contr, admin) in
    let () = Test.set_source admin in
    let new_metadata = Map.literal [("whatever", 0x45)] in
    let new_tokens_metadata = Map.literal [(1n, new_metadata)] in
    let r = Collection_helper.change_tokens_metadata(new_tokens_metadata, 10tez, collec.contr) in
    Assert.string_failure r Collection.Errors.expects_0_tez
