// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import {ERC1155Pausable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

contract Propiedad is ERC1155, AccessControl, ERC1155Pausable, ERC1155Burnable, ERC1155Supply, ReentrancyGuard {
    // Custom errors for better gas efficiency
    error InvalidTokenPrice();
    error InvalidMaxSupply();
    error NotEnoughAllowance();

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    uint256 public tokenPrice; // Price per token
    uint256 public maxSupply;  // Max supply
    address public developerAddress;
    address public comissionAddress;
    uint256 purchaseComissions;
    IERC20 public paymentToken;

    event TokensPurchased(address indexed buyer, uint256 indexed tokenID, uint256 amountTokens, uint256 totalPrice);
    
    constructor(
        address admin,                  // Address of the contract administrator
        uint256 _tokenPrice,            // Price per token
        uint256 _maxSupply,             // Max token supply
        string memory _initialUri,      // Initial URI for the token
        address _developerAddress,      // Address of the developer to receive the payments
        address _comissionAddress,      // Address of the comission to receive the payments
        uint256 _purchaseComissions,    // Comission of every purchase to send to the comission address
        address _paymentToken           // Token to use for payments

    ) ERC1155(_initialUri) {
        require(_tokenPrice > 0, InvalidTokenPrice());
        require(_maxSupply > 0,  InvalidMaxSupply());
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(PAUSER_ROLE, msg.sender);

        tokenPrice = _tokenPrice;
        maxSupply = _maxSupply;
        developerAddress = _developerAddress;
        comissionAddress = _comissionAddress;
        purchaseComissions = _purchaseComissions;
        paymentToken = IERC20(_paymentToken);
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        _mintBatch(to, ids, amounts, data);
    }

    function makePurchase(uint256 amountTokens, uint256 tokenID) public nonReentrant {
        require(amountTokens > 0, "Amount must be greater than zero");
        require(totalSupply(tokenID) + amountTokens <= maxSupply, "Exceeds max supply");

        uint256 totalAmountToPay = amountTokens * tokenPrice;
        uint256 comission = totalAmountToPay * (purchaseComissions / 100);
        uint256 amountToPaydeveloper = totalAmountToPay - comission;
        uint256 amountToPaycomission = comission;

        // Transfer the payment from the buyer to this contract
        bool comissionSuccess = paymentToken.transferFrom(msg.sender, comissionAddress, amountToPaycomission);
        bool mainPaypemtSuccess = paymentToken.transferFrom(msg.sender, developerAddress, amountToPaydeveloper); 
        
        require(comissionSuccess, NotEnoughAllowance());
        require(mainPaypemtSuccess, NotEnoughAllowance());
        _mint(msg.sender, tokenID, amountTokens, ""); // Mint the purchased tokens

        emit TokensPurchased(msg.sender, tokenID, amountTokens, totalAmountToPay);
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
