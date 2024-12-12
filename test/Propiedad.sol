// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../src/Propiedad.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "./utils/MockERC20.sol";
import "./utils/Setup.sol";

contract PropiedadTest is Setup, ERC1155Holder {

    function testConstructor() public view {
        assertEq(propiedad.paymentReceiver(), paymentReceiver);
        assertEq(propiedad.commissionAddress(), commissionAddress);
        assertEq(propiedad.getUnitPrice(), unitPrice);
        assertEq(propiedad.getMaxSupply(), maxSupply);
        assertEq(propiedad.getCommissionRate(), commissionRate);
    }

    function testToggleTokenEnabled() public {
        propiedad.toggleTokenEnabled(0);
        assertTrue(!propiedad.tokenEnabled(0), "Token should be disabled");

        propiedad.toggleTokenEnabled(0);
        assertTrue(propiedad.tokenEnabled(0), "Token should be enabled");
    }

    function testMakePurchase() public {
        // Simulate a purchase
        uint256 amountToPurchase = 1;
        uint256 unitPrice = propiedad.getUnitPrice();
        uint256 balanceBefore = paymentToken.balanceOf(address(this));
        uint256 totalToSpend = amountToPurchase * unitPrice;
        propiedad.makePurchase(0, amountToPurchase); // Purchase 1 token
        
        assertEq(propiedad.totalSupply(0) - amountToPurchase, propiedad.balanceOf(address(propiedad), 0), "Total supply should be ");

        // Check the balance of the sender
        assertEq(propiedad.balanceOf(address(this), 0), amountToPurchase, "Sender's balance should match the amount bought");
        assertEq(balanceBefore-totalToSpend, paymentToken.balanceOf(address(this)), "The balance of the buyer should reflect the spending");
    }

    function testUpdatePrice() public {
        uint256 newPrice = 2 ether;
        propiedad.updatePrice(0, newPrice);
        assertEq(propiedad.getUnitPrice(), newPrice, "Unit price should be updated");
    }

    function testMakePurchaseExceedsMaxSupply() public {
        uint256 amountToPurchase = maxSupply;
        uint256 totalToSpend = amountToPurchase * propiedad.getUnitPrice();

        // Set allowance to totalToSpend
        paymentToken.approve(address(propiedad), totalToSpend);
        propiedad.makePurchase(0, maxSupply + 1); // Purchase max supply
        vm.expectRevert(abi.encodeWithSelector(Propiedad.MaxSupplyExceeded.selector, 1, 0));
        propiedad.makePurchase(0, 1); // Attempt to purchase one more token
    }

    function testMakePurchaseTokenNotEnabled() public {
        // Disabling token
        propiedad.toggleTokenEnabled(0);

        vm.expectRevert(abi.encodeWithSelector(Propiedad.InvalidConfiguration.selector, "Token not enabled"));
        propiedad.makePurchase(0, 1 ether); // Attempt to purchase when token is disabled
    }

    function testUpdatePriceInvalid() public {
        vm.expectRevert(abi.encodeWithSelector(Propiedad.InvalidConfiguration.selector, "Invalid price"));
        propiedad.updatePrice(0, 0); // Attempt to set price to zero
    }

    function testToggleTokenEnabledByNonManager() public {
        address nonManager = vm.addr(3); // Create a non-manager address
        vm.prank(nonManager); // Simulate a call from a non-manager
        vm.expectRevert("AccessControl: account is missing role"); // Expect access control revert
        propiedad.toggleTokenEnabled(0); // Attempt to toggle token enabled status
    }

    function testMakePurchaseInsufficientFunds() public {
        uint256 amountToPurchase = 1;
        uint256 totalToSpend = amountToPurchase * propiedad.getUnitPrice();

        // Set allowance to a value less than totalToSpend
        paymentToken.approve(address(propiedad), totalToSpend - 1); // Approve just below the required amount

        vm.expectRevert(abi.encodeWithSelector(Propiedad.InsufficientFunds.selector, totalToSpend, totalToSpend - 1));
        propiedad.makePurchase(0, amountToPurchase); // Attempt to purchase without sufficient funds
    }

    // Additional tests for error handling and edge cases can be added here
}
