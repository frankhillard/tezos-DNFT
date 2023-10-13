#import "../helpers/marketplace.mligo" "Marketplace_helper"
#import "../helpers/collection.mligo" "Collection_helper"

let boot_accounts () =
    let () = Test.reset_state 6n ([] : tez list) in
    let accounts =
        Test.nth_bootstrap_account 1,
        Test.nth_bootstrap_account 2,
        Test.nth_bootstrap_account 3,
        Test.nth_bootstrap_account 4
    in
    accounts

(* Boostrapping of the test environment for Collection *)
let boot_collection (balance : tez) =
    let () = Test.reset_state 6n ([] : tez list) in

    let (admin, creator) =
        Test.nth_bootstrap_account 1,
        Test.nth_bootstrap_account 2
    in
    let accounts = admin, creator,
        Test.nth_bootstrap_account 3,
        Test.nth_bootstrap_account 4,
        Test.nth_bootstrap_account 5
    in

    let collection = Collection_helper.originate_from_file(
        Collection_helper.base_storage(admin), balance
    ) in
    (accounts, collection)

(* Boostrapping of the test environment for Marketplace *)
let boot_marketplace () =
    let () = Test.reset_state 6n ([] : tez list) in

    let (admin, creator) =
        Test.nth_bootstrap_account 1,
        Test.nth_bootstrap_account 2
    in
    let accounts = admin, creator,
        Test.nth_bootstrap_account 3,
        Test.nth_bootstrap_account 4,
        Test.nth_bootstrap_account 5
    in
    let mp = Marketplace_helper.originate(Marketplace_helper.base_storage) in
    let collection = Collection_helper.originate_from_file(
        Collection_helper.base_storage(admin), 0tez
    ) in
    (accounts, mp, collection)
