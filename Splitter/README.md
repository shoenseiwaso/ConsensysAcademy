# Consensys Academy: Splitter

## Usage

Checkout the repo into a directory called `jeff`. Use the `--recursive` flag to pull in the [easy-geth-dev-mode](https://github.com/curvegrid/easy-geth-dev-mode) submodule for running a private testnet.

```sh
git clone --recursive git@github.com:shoenseiwaso/ConsensysAcademy.git ./jeff
```

Launch the private test network in one terminal.

```sh
$ cd jeff/Splitter
$ ./launch-testnet.sh
```

In a different terminal, try testing the Splitter contract.

```sh
$ cd jeff/Splitter
$ truffle test
Using network 'development'.

  Contract: Splitter
    ✓ should add a valid splitter with Alice, Bob and Carol (3044ms)
    ✓ should refuse to add a duplicate splitter (same 'from' address) (5312ms)
    ✓ should add a valid splitter with Alice, Bob and Carol, then a second one with Bob, David and Emma, with an odd amount of wei (4030ms)

  3 passing (16s)
$
```

## Base requirements

You will create a smart contract named Splitter whereby:

- [x] there are 3 people: Alice, Bob and Carol
- [x] we can see the balance of the Splitter contract on the web page *(note: did not implement web page, only wrote the contract such that it could be read from a web page)*
- [x] whenever Alice sends ether to the contract, half of it goes to Bob and the other half to Carol
- [x] we can see the balances of Alice, Bob and Carol on the web page *(see note above)*
- [x] we can send ether to it from the web page *(see note above)*
- [ ] It would be even better if you could team up with different people impersonating Alice, Bob and Carol, all cooperating on a test net. *(used private geth instance)*

## Stretch goals:

- [x] add a kill switch to the whole contract
- [x] make the contract a utility that can be used by David, Emma and anybody with an address
- [x] cover potentially bad input data