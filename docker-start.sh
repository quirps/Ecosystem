#!/bin/sh

# Start the Express server in the background
echo "Starting Express server..."
node ./server.js &

# Start the Hardhat node in the background
echo "Starting Hardhat node..."
npx hardhat node --network hardhat --no-deploy &

# Wait for any background process to exit
# This ensures the container keeps running as long as one process is active
wait -n

# Exit with the status of the last exited background process (optional, but good practice)
exit $?