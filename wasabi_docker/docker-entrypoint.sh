#!/usr/bin/env sh

# Tor is not running as part of Cyphernode, try to kill it locally in here
termi_wtor() {
  echo "SIGTERM or SIGINT detected!"

  local dotnetpid=$(pidof dotnet)
  local torpid=$(pidof tor)
  echo "dotnetpid=${dotnetpid}"
  echo "torpid=${torpid}"

  kill -TERM ${dotnetpid} ${torpid}
  echo "Waiting for dotnet and tor to end..."

  while [ -e /proc/${dotnetpid} ] && [ -e /proc/${torpid} ]; do sleep 1; done
}

# Tor is running as part of Cyphernode, don't try to kill it locally in here
termi_wotor() {
  echo "SIGTERM or SIGINT detected!"

  local dotnetpid=$(pidof dotnet)

  echo "dotnetpid=${dotnetpid}"

  kill -TERM ${dotnetpid}
  echo "Waiting for dotnet to end..."

  while [ -e /proc/${dotnetpid} ]; do sleep 1; done
}

# If TOR_HOST is defined, it means Tor has been installed in Cyphernode setup, use it!
if [ -n "${TOR_HOST}" ]; then
  trap termi_wotor TERM INT
else
  trap termi_wtor TERM INT
fi

trim() {
	echo -e "$1" | sed -e 's/^[[:space:]]*//' | sed -e 's/[[:space:]]*$//'
}

user=$( trim ${WASABI_RPC_USER} )
echo "user=${user}" > ${WASABI_RPC_CFG}

wallet_name=${WALLET_NAME:-wasabi}

# check if we have a wallet file
network=$(cat /root/.walletwasabi/client/Config.json | jq -r '.Network')

# If TOR_HOST is defined, it means Tor has been installed in Cyphernode setup, use it!
if [ -n "${TOR_HOST}" ]; then
  while [ -z "${TOR_IP}" ]; do echo "tor not ready" ; TOR_IP=$(getent hosts tor | awk '{ print $1 }') ; sleep 10 ; done
  echo "tor ready at IP ${TOR_IP}"
  cp /root/.tor/control_auth_cookie /root/.walletwasabi/client/control_auth_cookie
fi

if [[ $network == "TestNet" || $network == "RegTest" ]]; then
  if [ ! -d "/root/.walletwasabi/client/Wallets/$network" ]; then
    echo "Missing wallet directory. Creating it"
    mkdir -p "/root/.walletwasabi/client/Wallets/$network"
  fi
  if [ ! -f "/root/.walletwasabi/client/Wallets/$network/$wallet_name.json" ]; then
    echo "Missing wallet file. Generating wallet with name $wallet_name and saving the seed words"
    /app/scripts/generateWallet.sh $wallet_name > "/root/.walletwasabi/client/Wallets/$network/$wallet_name.seed"
  fi
else
  if [ ! -f "/root/.walletwasabi/client/Wallets/$wallet_name.json" ]; then
    echo "Missing wallet file. Generating wallet with name $wallet_name and saving the seed words"
    /app/scripts/generateWallet.sh $wallet_name > "/root/.walletwasabi/client/Wallets/$wallet_name.seed"
  fi
fi
  
dotnet WalletWasabi.Daemon.dll --wallet=$wallet_name &
wait $!
