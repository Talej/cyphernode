#!/usr/bin/env sh

# If TOR_HOST is not defined, it means Tor has not been installed in Cyphernode setup,
# let's launch a local instance!
if [ -z "${TOR_HOST}" ]; then
  tor &
fi

dotnet run WalletWasabi.Daemon.dll --wallet:$1
