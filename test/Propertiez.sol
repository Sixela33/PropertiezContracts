pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../src/Propiedad.sol";
import "../src/Propertiez.sol";

contract PropertiezTest is Test {
    Propertiez propertiez;
    address defaultAdmin = address(this);
    address pauser = address(0x2);
    address lister = address(0x3);
    address paymentReceiver = address(0x4);
    address paymentToken = address(0x5);
    uint256 price = 1 ether;
    uint256 maxSupply = 100;
    uint256 commissionRate = 5;
    uint256 numTokens = 10;
    string uri = "http://example.com";

    function setUp() public {
        propertiez = new Propertiez(pauser);
        
        // Grant roles to the lister and pauser
        vm.prank(defaultAdmin);
        propertiez.grantRole(propertiez.LISTER_ROLE(), lister);
        
        vm.prank(defaultAdmin);
        propertiez.grantRole(propertiez.PAUSER_ROLE(), pauser);
    }

    function testPause() public {
        vm.prank(pauser);
        propertiez.pause();
        assertTrue(propertiez.paused(), "Contract should be paused");
    }

    function testUnpause() public {
        vm.prank(pauser);
        propertiez.pause();
        vm.prank(pauser);
        propertiez.unpause();
        assertFalse(propertiez.paused(), "Contract should be unpaused");
    }

    function testCreateProperty() public {
        vm.prank(lister);
        address newProperty = propertiez.createProperty(paymentReceiver, paymentToken, price, maxSupply, commissionRate, numTokens, uri);
        assertNotEq(newProperty, address(0), "New property address should not be zero");
        assertEq(propertiez.properties(0), newProperty, "Property should be stored correctly");
    }

    function testCreateMultipleProperties() public {
        vm.prank(lister);
        address property1 = propertiez.createProperty(paymentReceiver, paymentToken, price, maxSupply, commissionRate, numTokens, uri);
        assertNotEq(property1, address(0), "First property address should not be zero");
        assertEq(propertiez.properties(0), property1, "First property should be stored correctly");

        vm.prank(lister);
        address property2 = propertiez.createProperty(paymentReceiver, paymentToken, price, maxSupply, commissionRate, numTokens, uri);
        assertNotEq(property2, address(0), "Second property address should not be zero");
        assertEq(propertiez.properties(1), property2, "Second property should be stored correctly");
    }

    function testCreatePropertyWithoutListerRole() public {
        // Attempt to create a property without the LISTER_ROLE
        vm.expectRevert(abi.encodeWithSignature("AccessControl: account is missing role"));
        propertiez.createProperty(paymentReceiver, paymentToken, price, maxSupply, commissionRate, numTokens, uri);
    }

    function testGetProperties() public {
        vm.prank(lister);
        propertiez.createProperty(paymentReceiver, paymentToken, price, maxSupply, commissionRate, numTokens, uri);
        vm.prank(lister);
        propertiez.createProperty(paymentReceiver, paymentToken, price, maxSupply, commissionRate, numTokens, uri);

        address[] memory properties = propertiez.getProperties();
        assertEq(properties.length, 2, "Should return the correct number of properties");
        assertNotEq(properties[0], address(0), "First property should not be zero");
        assertNotEq(properties[1], address(0), "Second property should not be zero");
    }
}