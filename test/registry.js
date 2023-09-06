const {
    expect,
    version
} = require("chai");
const {
    ethers
} = require("hardhat");

const {
    getSelectors
} = require("../scripts/libraries/diamond")
describe("DiamondRegistry", () => {
    let diamondRegistry;
    let owner;
    let deployDiamondAddress;
    let diamondAddress;
    let nonOwner;
    let diamondBytecode;
    let diamondLoupeFacet;
    let diamondCutFacet;
    let facets = [];
    before(async () => {
        [owner, nonOwner] = await ethers.getSigners();
        const DiamondRegistry = await ethers.getContractFactory("DiamondRegistry");
        diamondRegistry = await DiamondRegistry.connect(owner).deploy();
        await diamondRegistry.deployed();

        //Diamond
        const Diamond = await ethers.getContractFactory("Diamond")
        diamondBytecode = Diamond.bytecode

        //DiamondCutFacet
        const DiamondCutFacet = await ethers.getContractFactory("DiamondCutFacet")
        diamondCutFacet = await DiamondCutFacet.deploy()
        await diamondCutFacet.deployed();
        //Obviously had to be cut within diamond deployment
        //facets.push( [ diamondCutFacet.address, getSelectors(DiamondCutFacet) ] )
        //DiamondDeploy
        const DiamondDeploy = await ethers.getContractFactory("DiamondDeploy");
        const diamondDeploy = await DiamondDeploy.connect(owner).deploy(diamondBytecode, diamondCutFacet.address);
        await diamondDeploy.deployed();

        deployDiamondAddress = diamondDeploy.address

        //deployFacets

        const DiamondLoupeFacet = await ethers.getContractFactory("DiamondLoupeFacet");
        diamondLoupeFacet = await DiamondLoupeFacet.deploy()
        await diamondLoupeFacet.deployed();
        facets.push([diamondLoupeFacet.address, getSelectors(DiamondLoupeFacet)])
        console.log(facets)
        //Ultimiately should automate facets in a particular version and their corresponding
        // signatures being deployed in all the tests 
        //Then initializations

    });

    describe("uploadVersion", () => {
        it("should allow the owner to upload a version", async () => {
            const versionNumber = 1;
            const optimizationMaps = [];


            await expect(diamondRegistry.uploadVersion(versionNumber, deployDiamondAddress, optimizationMaps, facets))
                .to.emit(diamondRegistry, 'VersionUploaded')
                .withArgs(versionNumber);

            const version = await diamondRegistry.getVersion(versionNumber);
            expect(version.diamondDeploy).to.equal(deployDiamondAddress);
        });

        it("should not allow a non-owner to upload a version", async () => {
            const versionNumber = 1;
            const diamonDeploydAddress = ethers.constants.AddressZero;
            const optimizationMaps = [];
            const facets = [];

            await expect(diamondRegistry.connect(nonOwner).uploadVersion(versionNumber, diamonDeploydAddress, optimizationMaps, facets))
                .to.be.revertedWith("Only owner can call this function");
        });
    });
    describe("deployVersion", () => {
        it("should deploy a new version correctly", async () => {
            const versionNumber = 1;
            const optimizationMaps = [];


            // Then, deploy this version

            diamondAddress = await diamondRegistry.callStatic.deployVersion(versionNumber, diamondBytecode)
            await expect(diamondRegistry.deployVersion(versionNumber, diamondBytecode))
                .to.emit(diamondRegistry, 'EcosystemDeployed')
                .withArgs(owner.address, diamondAddress, versionNumber); // You can extend this to check other event arguments

            const userEcosystems = await diamondRegistry.getUserEcosystems(owner.address);
            expect(userEcosystems.length).to.equal(1);
            expect(userEcosystems[0].versionNumber).to.equal(versionNumber);
        });
        it("should retrieve facet addresses from LoupeFacet", async () => {
            let _facetAddresses = [diamondCutFacet.address, diamondLoupeFacet.address]
                
            const _diamondLoupeFacet = await ethers.getContractAt("DiamondLoupeFacet",diamondAddress);
            let facetAddresses = await _diamondLoupeFacet.callStatic.facetAddresses();
            expect(_facetAddresses).to.deep.equal(facetAddresses);

        })
    });
    describe("upgradeVersion", function () {
        let newVersionNumber = 2;
        let ecosystemIndex = 0;
        it("Should successfully upgrade version", async function () {
            // Arrange
            // Add necessary setup logic like creating an ecosystem, adding versions etc.
            const optimizationMaps = [];

            let newFacets = facets.slice();

            // add new facet 
            const OwnershipFacet = await ethers.getContractFactory("OwnershipFacet");
            const ownershipFacet = await OwnershipFacet.deploy();
            await ownershipFacet.deployed();
            const currentEcosystem = await diamondRegistry.getUserEcosystems(owner.address);
            newFacets.push([ownershipFacet.address, getSelectors(ownershipFacet)])
            await expect(diamondRegistry.uploadVersion(newVersionNumber, deployDiamondAddress, optimizationMaps, newFacets))
            // If you have an event named VersionUpgraded, you can also check it here
            await expect(diamondRegistry.connect(owner).upgradeVersion(newVersionNumber, ecosystemIndex))
                .to.emit(diamondRegistry, "VersionUpgraded")
                .withArgs(newVersionNumber, currentEcosystem[0].versionNumber, owner.address);

            const newEcosystem = await diamondRegistry.getUserEcosystems(owner.address);

            // Assert
            expect(newEcosystem[0].versionNumber).to.equal(newVersionNumber);
        });

        it("Should fail if user has no ecosystem", async function () {
            // Arrange
            // No setup of ecosystems for addr1

            // Act & Assert
            await expect(diamondRegistry.connect(owner).upgradeVersion(newVersionNumber, ecosystemIndex))
                .to.be.revertedWith("New version should be greater than current version");
        });

        // Add other test cases as needed
    });
    // Similarly, add more test cases for other functions
    // 1. Test for `deployVersion`
    // 2. Test for `getVersion`
    // 3. Test for `upgradeVersion`
    // 4. Test for `uploadOptimizedFacets` etc.
});


//Want to test registry itself
//Just need to give addresses.
//