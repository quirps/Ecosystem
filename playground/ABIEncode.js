const {ethers} = require("ethers")

let abiCoder = ethers.utils.defaultAbiCoder
var data = abiCoder.encode(["uint256","address","address"], [429,"0xb79872DC1E960B7C6B9b5E832dD55D9c2bf653cb","0xDAFEA492D9c6733ae3d56b7Ed1ADB60692c98Bc5"]);
console.log(data)