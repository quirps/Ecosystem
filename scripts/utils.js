async function encodeCallData(contractName, functionName, args) {
    // Get the contract factory
    const Contract = await ethers.getContractFactory(contractName);

    // Get the interface of the contract
    const contractInterface = Contract.interface;

    // Encode the function data with its selector
    const callData = contractInterface.encodeFunctionData(functionName, args);

    return callData;
}

module.exports = {encodeCallData}