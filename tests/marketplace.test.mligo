#import "./helpers/assert.mligo" "Assert"
#import "./bootstrap/bootstrap.mligo" "Bootstrap"
#import "./helpers/log.mligo" "Log"
#import "./helpers/marketplace.mligo" "Marketplace_helper"
#import "./helpers/collection.mligo" "Collection_helper"
#import "../src/marketplace/main.mligo" "Marketplace"
#import "../src/collection/main.mligo" "Collection"

let () = Log.describe("[Marketplace] test suite")

let bootstrap () = Bootstrap.boot_marketplace()

let test_success_buy =
    let (accounts, mp, nft) = bootstrap() in
    let (admin, other, alice, _bob, _) = accounts in
    //let () = Test.set_source other in
    let () = Test.set_source admin in
    let () = Collection_helper.authorize_success([other], 0tez, nft.contr) in
    let () = Collection_helper.with_preminted(other, nft.contr, admin) in
    //let () = Test.set_source other in
    //let () = Collection_helper.mint_success(Map.literal [(0n, 1n)], 10tez, nft.contr) in
    //let () = Test.set_source creator in
    let () = Collection_helper.update_operators_success([Add_operator({
        owner = other;
        operator = mp.addr;
        token_id = 0n
    })], nft.contr) in
    let () = Marketplace_helper.sell_success({
        token_id = 0n;
        collectionContract = nft.addr;
        price = 1tez;
        amount = 1n;
    }, mp.contr) in
    let () = Test.set_source alice in
    Marketplace_helper.buy_success({ proposal_id=0n }, 1tez, mp.contr)