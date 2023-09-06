"use strict";

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance"); }

function _iterableToArrayLimit(arr, i) { if (!(Symbol.iterator in Object(arr) || Object.prototype.toString.call(arr) === "[object Arguments]")) { return; } var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

var _require = require("chai"),
    expect = _require.expect,
    version = _require.version;

var _require2 = require("hardhat"),
    ethers = _require2.ethers;

var _require3 = require("../scripts/libraries/diamond"),
    getSelectors = _require3.getSelectors;

describe("DiamondRegistry", function () {
  var diamondRegistry;
  var owner;
  var diamondAddress;
  var nonOwner;
  var diamondBytecode;
  var diamondLoupeFacet;
  var diamondCutFacet;
  var facets = [];
  before(function _callee() {
    var _ref, _ref2, DiamondRegistry, Diamond, DiamondCutFacet, DiamondDeploy, diamondDeploy, DiamondLoupeFacet;

    return regeneratorRuntime.async(function _callee$(_context) {
      while (1) {
        switch (_context.prev = _context.next) {
          case 0:
            _context.next = 2;
            return regeneratorRuntime.awrap(ethers.getSigners());

          case 2:
            _ref = _context.sent;
            _ref2 = _slicedToArray(_ref, 2);
            owner = _ref2[0];
            nonOwner = _ref2[1];
            _context.next = 8;
            return regeneratorRuntime.awrap(ethers.getContractFactory("DiamondRegistry"));

          case 8:
            DiamondRegistry = _context.sent;
            _context.next = 11;
            return regeneratorRuntime.awrap(DiamondRegistry.connect(owner).deploy());

          case 11:
            diamondRegistry = _context.sent;
            _context.next = 14;
            return regeneratorRuntime.awrap(diamondRegistry.deployed());

          case 14:
            _context.next = 16;
            return regeneratorRuntime.awrap(ethers.getContractFactory("Diamond"));

          case 16:
            Diamond = _context.sent;
            diamondBytecode = Diamond.bytecode; //DiamondCutFacet

            _context.next = 20;
            return regeneratorRuntime.awrap(ethers.getContractFactory("DiamondCutFacet"));

          case 20:
            DiamondCutFacet = _context.sent;
            _context.next = 23;
            return regeneratorRuntime.awrap(DiamondCutFacet.deploy());

          case 23:
            diamondCutFacet = _context.sent;
            _context.next = 26;
            return regeneratorRuntime.awrap(diamondCutFacet.deployed());

          case 26:
            _context.next = 28;
            return regeneratorRuntime.awrap(ethers.getContractFactory("DiamondDeploy"));

          case 28:
            DiamondDeploy = _context.sent;
            _context.next = 31;
            return regeneratorRuntime.awrap(DiamondDeploy.connect(owner).deploy(diamondBytecode, diamondCutFacet.address));

          case 31:
            diamondDeploy = _context.sent;
            _context.next = 34;
            return regeneratorRuntime.awrap(diamondDeploy.deployed());

          case 34:
            diamondAddress = diamondDeploy.address; //deployFacets

            _context.next = 37;
            return regeneratorRuntime.awrap(ethers.getContractFactory("DiamondLoupeFacet"));

          case 37:
            DiamondLoupeFacet = _context.sent;
            _context.next = 40;
            return regeneratorRuntime.awrap(DiamondDeploy.connect(owner).deploy(diamondBytecode, diamondCutFacet.address));

          case 40:
            diamondLoupeFacet = _context.sent;
            _context.next = 43;
            return regeneratorRuntime.awrap(diamondLoupeFacet.deployed());

          case 43:
            facets.push([diamondLoupeFacet.address, getSelectors(DiamondLoupeFacet)]);
            console.log(facets); //Ultimiately should automate facets in a particular version and their corresponding
            // signatures being deployed in all the tests 
            //Then initializations

          case 45:
          case "end":
            return _context.stop();
        }
      }
    });
  });
  describe("uploadVersion", function () {
    it("should allow the owner to upload a version", function _callee2() {
      var versionNumber, optimizationMaps, version;
      return regeneratorRuntime.async(function _callee2$(_context2) {
        while (1) {
          switch (_context2.prev = _context2.next) {
            case 0:
              versionNumber = 1;
              optimizationMaps = [];
              _context2.next = 4;
              return regeneratorRuntime.awrap(expect(diamondRegistry.uploadVersion(versionNumber, diamondAddress, optimizationMaps, facets)).to.emit(diamondRegistry, 'VersionUploaded').withArgs(versionNumber));

            case 4:
              _context2.next = 6;
              return regeneratorRuntime.awrap(diamondRegistry.getVersion(versionNumber));

            case 6:
              version = _context2.sent;
              expect(version.diamondDeploy).to.equal(diamondAddress);

            case 8:
            case "end":
              return _context2.stop();
          }
        }
      });
    });
    it("should not allow a non-owner to upload a version", function _callee3() {
      var versionNumber, diamondAddress, optimizationMaps, facets;
      return regeneratorRuntime.async(function _callee3$(_context3) {
        while (1) {
          switch (_context3.prev = _context3.next) {
            case 0:
              versionNumber = 1;
              diamondAddress = ethers.constants.AddressZero;
              optimizationMaps = [];
              facets = [];
              _context3.next = 6;
              return regeneratorRuntime.awrap(expect(diamondRegistry.connect(nonOwner).uploadVersion(versionNumber, diamondAddress, optimizationMaps, facets)).to.be.revertedWith("Only owner can call this function"));

            case 6:
            case "end":
              return _context3.stop();
          }
        }
      });
    });
  });
  describe("deployVersion", function () {
    it("should deploy a new version correctly", function _callee4() {
      var versionNumber, optimizationMaps, deployedDiamondAddress, userEcosystems;
      return regeneratorRuntime.async(function _callee4$(_context4) {
        while (1) {
          switch (_context4.prev = _context4.next) {
            case 0:
              versionNumber = 1;
              optimizationMaps = []; // Then, deploy this version

              _context4.next = 4;
              return regeneratorRuntime.awrap(diamondRegistry.callStatic.deployVersion(versionNumber, diamondBytecode));

            case 4:
              deployedDiamondAddress = _context4.sent;
              _context4.next = 7;
              return regeneratorRuntime.awrap(expect(diamondRegistry.deployVersion(versionNumber, diamondBytecode)).to.emit(diamondRegistry, 'EcosystemDeployed').withArgs(owner.address, deployedDiamondAddress, versionNumber));

            case 7:
              _context4.next = 9;
              return regeneratorRuntime.awrap(diamondRegistry.getUserEcosystems(owner.address));

            case 9:
              userEcosystems = _context4.sent;
              expect(userEcosystems.length).to.equal(1);
              expect(userEcosystems[0].versionNumber).to.equal(versionNumber);

            case 12:
            case "end":
              return _context4.stop();
          }
        }
      });
    });
    it("should retrieve facet addresses from LoupeFacet", function _callee5() {
      var _facetAddresses, _diamondLoupeFacet, facetAddresses;

      return regeneratorRuntime.async(function _callee5$(_context5) {
        while (1) {
          switch (_context5.prev = _context5.next) {
            case 0:
              _facetAddresses = [diamondCutFacet.address, diamondLoupeFacet.address];
              _context5.next = 3;
              return regeneratorRuntime.awrap(ethers.getContractAt("DiamondLoupeFacet", diamondAddress));

            case 3:
              _diamondLoupeFacet = _context5.sent;
              _context5.next = 6;
              return regeneratorRuntime.awrap(_diamondLoupeFacet.callStatic.facetAddresses());

            case 6:
              facetAddresses = _context5.sent;
              expect(_facetAddresses).to.equal(facetAddresses);

            case 8:
            case "end":
              return _context5.stop();
          }
        }
      });
    });
  });
  describe("upgradeVersion", function () {
    var newVersionNumber = 2;
    var ecosystemIndex = 0;
    it("Should successfully upgrade version", function _callee6() {
      var optimizationMaps, newFacets, OwnershipFacet, ownershipFacet, currentEcosystem, newEcosystem;
      return regeneratorRuntime.async(function _callee6$(_context6) {
        while (1) {
          switch (_context6.prev = _context6.next) {
            case 0:
              // Arrange
              // Add necessary setup logic like creating an ecosystem, adding versions etc.
              optimizationMaps = [];
              newFacets = facets.slice(); // add new facet 

              _context6.next = 4;
              return regeneratorRuntime.awrap(ethers.getContractFactory("OwnershipFacet"));

            case 4:
              OwnershipFacet = _context6.sent;
              _context6.next = 7;
              return regeneratorRuntime.awrap(OwnershipFacet.deploy());

            case 7:
              ownershipFacet = _context6.sent;
              _context6.next = 10;
              return regeneratorRuntime.awrap(ownershipFacet.deployed());

            case 10:
              _context6.next = 12;
              return regeneratorRuntime.awrap(diamondRegistry.getUserEcosystems(owner.address));

            case 12:
              currentEcosystem = _context6.sent;
              newFacets.push([ownershipFacet.address, getSelectors(ownershipFacet)]);
              _context6.next = 16;
              return regeneratorRuntime.awrap(expect(diamondRegistry.uploadVersion(newVersionNumber, diamondAddress, optimizationMaps, newFacets)));

            case 16:
              _context6.next = 18;
              return regeneratorRuntime.awrap(expect(diamondRegistry.connect(owner).upgradeVersion(newVersionNumber, ecosystemIndex)).to.emit(diamondRegistry, "VersionUpgraded").withArgs(newVersionNumber, currentEcosystem[0].versionNumber, owner.address));

            case 18:
              _context6.next = 20;
              return regeneratorRuntime.awrap(diamondRegistry.getUserEcosystems(owner.address));

            case 20:
              newEcosystem = _context6.sent;
              // Assert
              expect(newEcosystem[0].versionNumber).to.equal(newVersionNumber);

            case 22:
            case "end":
              return _context6.stop();
          }
        }
      });
    });
    it("Should fail if user has no ecosystem", function _callee7() {
      return regeneratorRuntime.async(function _callee7$(_context7) {
        while (1) {
          switch (_context7.prev = _context7.next) {
            case 0:
              _context7.next = 2;
              return regeneratorRuntime.awrap(expect(diamondRegistry.connect(owner).upgradeVersion(newVersionNumber, ecosystemIndex)).to.be.revertedWith("New version should be greater than current version"));

            case 2:
            case "end":
              return _context7.stop();
          }
        }
      });
    }); // Add other test cases as needed
  }); // Similarly, add more test cases for other functions
  // 1. Test for `deployVersion`
  // 2. Test for `getVersion`
  // 3. Test for `upgradeVersion`
  // 4. Test for `uploadOptimizedFacets` etc.
}); //Want to test registry itself
//Just need to give addresses.
//