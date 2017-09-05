# Consensys Academy: Webpack Test

## Usage

Checkout the repo into a directory called `jeff`. Use the `--recursive` flag to pull in the [easy-geth-dev-mode](https://github.com/curvegrid/easy-geth-dev-mode) submodule for running a private testnet.

```sh
git clone --recursive git@github.com:shoenseiwaso/ConsensysAcademy.git ./jeff
```

Launch the private test network in one terminal.

```sh
$ cd jeff/webpack_test
$ ./launch-testnet.sh
```

In a different terminal, launch a simple web server.

```sh
$ cd jeff/webpack_test/build/app
$ python -m SimpleHTTPServer 8000
Serving HTTP on 0.0.0.0 port 8000 ...
```

In a different terminal, compile and deploy the smart contract, and build the front-end.

```sh
$ ./node_modules/.bin/truffle build
```

Then open a browser to http://localhost:8000.

## Future deployments

Use the base `webpack.config.js` to kickstart an empty project.

```sh
$ truffle init webpack
$ npm install
$ truffle migrate
$ npm run dev
```