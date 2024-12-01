// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import { Propiedad } from './Propiedad.sol';

contract Desarollo {
    
    address[] propiedades;   // array de propiedades manaejadas por el contrato
    string uri;              // Information about the development
    address paymentToken;    // Token en el que se realizaran los pagos
    address builderAddress;  // Direccion de la persona que hace el desarollo
    address propertiezVault; // Direccion donde irán las comisiones
    uint256 comission;       // Porcentaje de comision

    constructor(
        string memory _uri, 
        address _paymentToken, 
        address _builderAddress, 
        address _propertiezVault, 
        uint256 _comission, 
        string[] memory _propertiesURI,
        uint256[] memory _tokenPrice, 
        uint256[] memory _maxSupply
    ) {
        if (_propertiesURI.length != _tokenPrice.length) {
            revert("Error: Length of propertiesURI and tokenPrice must be equal.");
        }

        if(_maxSupply.length != _tokenPrice.length) {
            revert("Error: Length of maxSupply and tokenPrice must be equal.");
        }

        paymentToken = _paymentToken;
        uri = _uri;
        builderAddress = _builderAddress;
        propertiezVault = _propertiezVault;
        comission = _comission;

        // for i in length _propertiesURI creates a Propiedad contract with the values at that 
        // index and then stores the address on the propiedades array
        for (uint256 i = 0; i < _propertiesURI.length; i++) {
            Propiedad propiedad = new Propiedad(
                address(this),
                _tokenPrice[i], 
                _maxSupply[i], 
                _propertiesURI[i],
                _paymentToken
            );
            propiedades.push(address(propiedad));
        }
    }

    function getPropiedades() public view returns (address[] memory) {
        return propiedades;
    }

    function getUri() public view returns(string memory) {
        return uri;
    }


}