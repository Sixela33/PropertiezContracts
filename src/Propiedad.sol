// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import {ERC1155Pausable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract Propiedad is ERC1155, AccessControl, ERC1155Pausable, ERC1155Burnable, ERC1155Supply, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Custom errors for gas-efficient error handling
    error InvalidConfiguration(string reason);
    error InsufficientFunds(uint256 required, uint256 available);
    error MaxSupplyExceeded(uint256 requested, uint256 available);
    error InvalidAddress(string param);
    error InvalidTokenConfiguration(string reason);
    error PurchaseExceedsLimit(uint256 requested, uint256 maxAllowed);
    
    // Roles for access control
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    mapping(uint256 => bool) public tokenEnabled;

    address public immutable paymentReceiver;
    address public immutable commissionAddress;
    IERC20 public immutable paymentToken;
    uint256 unitPrice; 
    uint256 maxSupply; 
    uint256 commissionRate;

    // Events with more comprehensive information
    event TokenConfigured(uint256 indexed tokenId, uint256 unitPrice, uint256 maxSupply, uint256 commissionRate);
    event TokenPurchased(
        address indexed buyer, 
        uint256 indexed tokenId, 
        uint256 amount, 
        uint256 totalPrice,
        uint256 commissionPaid
    );
    event TokenEnabledStatusChanged(uint256 indexed tokenId, bool enabled);
    event TokenConfigUpdated(uint256 indexed tokenId, uint256 unitPrice);

    constructor(
        address admin,
        address _paymentReceiver,
        address _commissionAddress,
        address _paymentToken,
        uint256 _price, 
        uint256 _maxSupply, 
        uint256 _commissionRate,
        uint256 _numTokens,
        string memory _uri
    ) ERC1155(_uri) {
        if (admin == address(0) || _paymentReceiver == address(0) || _commissionAddress == address(0)) 
            revert InvalidConfiguration("Invalid addresses");

        _validateConstructorInputs(
            admin, 
            _paymentReceiver, 
            _commissionAddress, 
            _numTokens
        );

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);

        paymentReceiver = _paymentReceiver;
        commissionAddress = _commissionAddress;
        paymentToken = IERC20(_paymentToken);
        unitPrice=_price;
        maxSupply=_maxSupply;
        commissionRate=_commissionRate;

        for(uint256 i=0; i<_numTokens; i++) {
            tokenEnabled[i] = true;
            emit TokenConfigured(i, unitPrice, maxSupply, commissionRate);
        }
    }

    function _validateConstructorInputs(
        address admin, 
        address _paymentReceiver, 
        address _commissionAddress,
        uint256 tokenCount
    ) private pure {
        if (admin == address(0)) revert InvalidAddress("Admin");
        if (_paymentReceiver == address(0)) revert InvalidAddress("PaymentReceiver");
        if (_commissionAddress == address(0)) revert InvalidAddress("CommissionAddress");
        if (tokenCount == 0) revert InvalidTokenConfiguration("No tokens configured");
    }

    // Stops the token from being purchased
    function toggleTokenEnabled(uint256 tokenId) external onlyRole(MANAGER_ROLE) {
        tokenEnabled[tokenId] = !tokenEnabled[tokenId];
        emit TokenEnabledStatusChanged(tokenId, tokenEnabled[tokenId]);
    }

    // User sends token he wishes to purchase and the ammount of paymentToken they wish to pay
    function makePurhcase(uint256 tokenId, uint256 amount) 
        external 
        nonReentrant 
        whenNotPaused
    {

        if (!tokenEnabled[tokenId]) 
            revert InvalidConfiguration("Token not enabled");

        if(totalSupply(tokenId) == maxSupply) 
            revert MaxSupplyExceeded(amount, 0);

        uint256 tokensToBePurchased = amount / unitPrice;

        if(totalSupply(tokenId) + tokensToBePurchased > maxSupply){
            tokensToBePurchased = maxSupply - totalSupply(tokenId);
        }

        uint256 totalPrice = unitPrice * tokensToBePurchased;
        uint256 commission = totalPrice * (commissionRate / 100);
        uint256 netPayment = totalPrice - commission;

        // Perform token transfers with SafeERC20
        paymentToken.safeTransferFrom(msg.sender, commissionAddress, commission);
        paymentToken.safeTransferFrom(msg.sender, paymentReceiver, netPayment);

        _mint(msg.sender, tokenId, amount, "");

        emit TokenPurchased(
            msg.sender, 
            tokenId, 
            amount, 
            totalPrice, 
            commission
        );
    }

    function updatePrice(uint256 tokenId, uint256 newPrice) external onlyRole(MANAGER_ROLE) {
        if (newPrice == 0) revert InvalidConfiguration("Invalid price");
        unitPrice = newPrice;
        emit TokenConfigUpdated(tokenId, newPrice);
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Pausable, ERC1155Supply)
    {
        super._update(from, to, ids, values);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
