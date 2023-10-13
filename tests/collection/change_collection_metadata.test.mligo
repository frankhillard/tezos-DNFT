#import "../helpers/assert.mligo" "Assert"
#import "../bootstrap/bootstrap.mligo" "Bootstrap"
#import "../helpers/log.mligo" "Log"
#import "../helpers/collection.mligo" "Collection_helper"
#import "../../src/collection/main.mligo" "Collection"

let () = Log.describe("[Collection.Change_collection_metadata] test suite")

let bootstrap () = Bootstrap.boot_collection(0tez)

(* Successful ChangeCollectionMetadata *)
let test_success_with_admin =
    let (accounts, collec) = bootstrap() in
    let (admin, _other, _alice, _, _) = accounts in
    let metadata_key = ("contents" : string) in
    let () = Collection_helper.assert_collection_metadata(collec.taddr, metadata_key, ("4d494e54454544" : bytes)) in
    let () = Test.set_source admin in
    let metadata_uri = ("4d494e544545445f434f4c4c454354494f4e" : bytes) in
    let metadata_map = Big_map.literal[(metadata_key, metadata_uri)] in
    let () = Collection_helper.change_collection_metadata_success(metadata_map, 0tez, collec.contr) in
    Collection_helper.assert_collection_metadata(collec.taddr, metadata_key, metadata_uri)

(* Failing ChangeCollectionMetadata because not admin *)
let test_failure_with_not_admin =
    let (accounts, collec) = bootstrap() in
    let (_admin, other, _, _, _) = accounts in
    let metadata_key = ("contents" : string) in
    let metadata_uri = ("4d494e544545445f434f4c4c454354494f4e" : bytes) in
    let metadata_map = Big_map.literal[(metadata_key, metadata_uri)] in
    let () = Test.set_source other in
    let r = Collection_helper.change_collection_metadata(metadata_map, 0tez, collec.contr) in
    Assert.string_failure r Collection.Errors.only_admin

(* Failing ChangeCollectionMetadata because amount not null *)
let test_failure_with_amount_not_null =
    let (accounts, collec) = bootstrap() in
    let (admin, _other, _, _, _) = accounts in
    let metadata_key = ("contents" : string) in
    let () = Collection_helper.assert_collection_metadata(collec.taddr, metadata_key, ("4d494e54454544" : bytes)) in
    let metadata_uri = ("4d494e544545445f434f4c4c454354494f4e" : bytes) in
    let metadata_map = Big_map.literal[(metadata_key, metadata_uri)] in
    let () = Test.set_source admin in
    let r = Collection_helper.change_collection_metadata(metadata_map, 10tez, collec.contr) in
    Assert.string_failure r Collection.Errors.expects_0_tez
