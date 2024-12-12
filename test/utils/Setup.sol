pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../../src/Propiedad.sol";
import "./MockERC20.sol";

contract Setup is Test {
    Propiedad propiedad;
    MockERC20 paymentToken; // Use the mock token
    address admin;
    address paymentReceiver;
    address commissionAddress;
    uint256 unitPrice = 1 ether;
    uint256 maxSupply = 100;
    uint256 commissionRate = 5; // 5%
    uint256 numTokens = 1;

    function setUp() public {
        admin = address(this);
        paymentReceiver = vm.addr(1); // Use a valid test account
        commissionAddress = vm.addr(2); // Use another valid test account
        paymentToken = new MockERC20(); // Deploy the mock token

        propiedad = new Propiedad(
            admin,
            paymentReceiver,
            commissionAddress,
            address(paymentToken), // Pass the mock token address
            unitPrice,
            maxSupply,
            commissionRate,
            numTokens,
            "https://token-uri.com"
        );

        // Approve the Propiedad contract to spend tokens on behalf of the user
        paymentToken.approve(address(propiedad), 1000 ether);
    }

    function getPropiedad() public view returns (Propiedad) {
        return propiedad;
    }
}