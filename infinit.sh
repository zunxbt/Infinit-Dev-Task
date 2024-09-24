#!/bin/bash

curl -s https://raw.githubusercontent.com/zunxbt/logo/main/logo.sh | bash
sleep 3

function show {
  echo -e "\e[1;34m$1\e[0m"
}


export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    show "Loading NVM..."
    echo
    source "$NVM_DIR/nvm.sh"
else
    show "NVM not found, installing NVM..."
    echo
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
    source "$NVM_DIR/nvm.sh"
fi


echo
show "Installing Node.js..."
echo
nvm install 22 && nvm alias default 22 && nvm use default
echo

show "Installing Foundry..."
echo
curl -L https://foundry.paradigm.xyz | bash
export PATH="$HOME/.foundry/bin:$PATH"
sleep 5
source ~/.bashrc
foundryup


show "Installing Bun..."
echo
curl -fsSL https://bun.sh/install | bash
export PATH="$HOME/.bun/bin:$PATH"
sleep 5
source ~/.bashrc
echo

show "Setting up Bun project..."
echo
mkdir ZunXBT && cd ZunXBT
bun init -y
bun add @infinit-xyz/cli
echo

show "Initializing Infinit CLI and generating account..."
echo
bunx infinit init
bunx infinit account generate
echo

read -p "What is your wallet address (Input the address from the step above) : " WALLET
echo
read -p "What is your account ID (entered in the step above) : " ACCOUNT_ID
echo

show "Copy this private key and save it somewhere, this is the private key of this wallet"
echo
bunx infinit account export $ACCOUNT_ID

sleep 5
echo
# Removing old deployUniswapV3Action script if exists
rm -rf src/scripts/deployUniswapV3Action.script.ts

cat <<EOF > src/scripts/deployUniswapV3Action.script.ts
import { DeployUniswapV3Action, type actions } from '@infinit-xyz/uniswap-v3/actions'
import type { z } from 'zod'

type Param = z.infer<typeof actions['init']['paramsSchema']>

// TODO: Replace with actual params
const params: Param = {
  // Native currency label (e.g., ETH)
  "nativeCurrencyLabel": 'ETH',

  // Address of the owner of the proxy admin
  "proxyAdminOwner": '$WALLET',

  // Address of the owner of factory
  "factoryOwner": '$WALLET',

  // Address of the wrapped native token (e.g., WETH)
  "wrappedNativeToken": '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'
}

// Signer configuration
const signer = {
  "deployer": "$ACCOUNT_ID"
}

export default { params, signer, Action: DeployUniswapV3Action }
EOF

show "Executing the UniswapV3 Action script..."
echo
bunx infinit script execute deployUniswapV3Action.script.ts
