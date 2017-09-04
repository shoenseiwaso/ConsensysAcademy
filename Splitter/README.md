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

In a different terminal, try testing the Splitter and Splitter Lite contracts.

```sh
$ cd jeff/Splitter
$ truffle test
Using network 'development'.

  Contract: Splitter
    ✓ should add a valid splitter with Alice, Bob and Carol (11105ms)
    ✓ should refuse to add a duplicate splitter (same 'from' address) (10082ms)
    ✓ should add a valid splitter with Alice, Bob and Carol, then a second one with Bob, David and Emma, with an odd amount of wei (5060ms)

  Contract: SplitterLite
    ✓ Alice splits an even amount of wei between Bob and Carol (3713ms)
    ✓ Alice splits an odd amount of wei between David and Emma, David withdraws, then contract is killed (9425ms)

  5 passing (49s)
$
```

## Base requirements: Splitter

You will create a smart contract named Splitter whereby:

- [x] there are 3 people: Alice, Bob and Carol
- [x] we can see the balance of the Splitter contract on the web page *(note: did not implement web page, only wrote the contract such that it could be read from a web page)*
- [x] whenever Alice sends ether to the contract, half of it goes to Bob and the other half to Carol
- [x] we can see the balances of Alice, Bob and Carol on the web page *(see note above)*
- [x] we can send ether to it from the web page *(see note above)*
- [ ] It would be even better if you could team up with different people impersonating Alice, Bob and Carol, all cooperating on a test net. *(used private geth instance)*

## Stretch goals: Splitter

- [x] add a kill switch to the whole contract
- [x] make the contract a utility that can be used by David, Emma and anybody with an address
- [x] cover potentially bad input data

## Splitter Lite, the lightweight version

Based on feedback from Rob:

1. *No need for a Splitter struct.*
2. *No need for a User struct.*
3. *No need for user profile concerns (name)*
4. *Include a way to withdraw funds*

*Basic data mapping: mapping(address => uint) balances;*

*Can you do it the fewest line of code possible?*