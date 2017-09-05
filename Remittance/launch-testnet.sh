#!/bin/bash

# Launch geth testnet with RPC enabled and attach an interactive console to it.
# Truffle will connect to this test net and use it for testing.
export GETH_TESTNET_BASEDIR="../net43"
${GETH_TESTNET_BASEDIR}/launch43.sh --startrpc