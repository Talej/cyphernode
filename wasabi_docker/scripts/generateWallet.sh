#!/usr/bin/env sh

dotnet WalletWasabi.Daemon.dll 1>/dev/null 2>&1 &

sleep 5

until pids=$(pidof dotnet)
do
    echo "waiting for dotnet"
    sleep 1
done

output=$(curl -s --config ${WASABI_RPC_CFG} -d "{\"jsonrpc\":\"2.0\",\"id\":\"0\",\"method\":\"createwallet\", \"params\":[\"${1}\", \"\"] }" localhost:18099)

#curl -s --config ${WASABI_RPC_CFG} -d "{\"jsonrpc\":\"2.0\",\"id\":\"0\",\"method\":\"createwallet\", \"params\":[\"${1}\", \"\"]}" localhost:18099 | jq -r '.result' | sed -e 's/"//g'

echo $output | jq -r '.result' | sed -e 's/"//g'

dotnet_pid=$(pidof dotnet)
kill -TERM $dotnet_pid 1&2>/dev/null