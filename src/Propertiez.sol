pragma solidity ^0.8.22;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Propiedad} from "./Propiedad.sol";

contract Propertiez is Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant LISTER_ROLE = keccak256("LISTER_ROLE");

    // Mapping to store created properties
    mapping(uint256 => address) public properties;
    uint256 public propertyCount;
    address[] propertiesArray;

    constructor(address pauser) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, pauser);
        _grantRole(LISTER_ROLE, pauser);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // Function to create a new property
    function createProperty(
        address _paymentReceiver,
        address _paymentToken,
        uint256 _price, 
        uint256 _maxSupply, 
        uint256 _commissionRate,
        uint256 _numTokens,
        string memory _uri
    ) public onlyRole(LISTER_ROLE) returns (address) {
        // Create a new instance of Propiedad
        Propiedad newProperty = new Propiedad(
            msg.sender, // admin
            _paymentReceiver,
            msg.sender,
            _paymentToken,
            _price,
            _maxSupply,
            _commissionRate,
            _numTokens,
            _uri
        );

        // Store the new property address
        properties[propertyCount] = address(newProperty);
        propertiesArray.push(address(newProperty));
        propertyCount++;

        return address(newProperty);
    }

    function getProperties() public view returns (address[] memory) {
        return propertiesArray;
    }
}