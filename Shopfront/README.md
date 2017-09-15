# Consensys Academy: Shopfront

## Usage

Checkout the repo into a directory called `jeff`. Use the `--recursive` flag to pull in the [easy-geth-dev-mode](https://github.com/curvegrid/easy-geth-dev-mode) submodule for running a private testnet.

```sh
git clone --recursive git@github.com:shoenseiwaso/ConsensysAcademy.git ./jeff
```

Launch the private test network in one terminal.

```sh
$ cd jeff/Shopfront
$ ./launch-testnet.sh
```

In a different terminal, try testing the Shopfront contract.

```sh
$ cd jeff/Shopfront
$ truffle test
Compiling ./contracts/Shopfront.sol...

$
```

## Architecture

The Shopfront is divided up into a series of smart contracts as follows.

* **Shopfront.sol**: the master contract. Spawns merchant contracts but also acts as a shopfront of its own. Collects a slice of income from each spawned merchant contract.
* **SKULibrary.sol**: central library of products. Owner and merchants can add and remove products.
* **ShopMerchant.sol**: merchant contract spawned by Shopfront master. Sends a slice of each sale back to master Shopfront contract.

## Base requirements: Shopfront

The project will start as a database whereby:
- [ ] as an administrator, you can add products, which consist of an id, a price and a stock.
- [ ] as a regular user you can buy 1 of the products.
- [ ] as the owner you can make payments or withdraw value from the contract.

Eventually, you will refactor it to include:
- [ ] ability to remove products.
- [ ] co-purchase by different people.
- [ ] add merchants akin to what Amazon has become.
- [ ] add the ability to pay with a third-party token.

## Stretch goals: Shopfront

### Hub and spoke
We have a hunch that you started with a single contract that does it all. How about you now move to a hub and spoke model?

- [ ] The hub would deploy the spokes
- [ ] Either the spokes send a sliver of the payment to the hub
- [ ] Or the hub keeps a cut of the payment
- [ ] How about a central sku repository for the shop(s)?

### Portability
Make your HTML and Javascript portable so that it works:

- [ ] in a regular browser, with a local Geth
- [ ] in Mist
- [ ] with Metamask and a public Geth