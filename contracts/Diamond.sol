// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
* 
* Implementation of a diamond.
/******************************************************************************/

import "../libraries/LibDiamond.sol";
import "../interfaces/IDiamondOwner.sol";
import "../interfaces/IDiamondLoupe.sol";
import "../interfaces/IDiamondCut.sol";
import "../interfaces/IERC173.sol";
import "../interfaces/IERC165.sol";

contract Diamond {

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    // more arguments are added to this struct
    // this avoids stack too deep errors
    struct DiamondArgs {
        address owner;
        address admin;
    }

    // constructor(IDiamondCut.FacetCut[] memory _diamondCut, DiamondArgs memory _args) payable {
    constructor(address _diamondCutFacet, DiamondArgs memory _args) payable {
        LibDiamond.setContractOwner(_args.owner);
        LibDiamond.setContractAdmin(_args.admin);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](5);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        functionSelectors[1] = IDiamondOwner.transferOwnership.selector;
        functionSelectors[2] = IDiamondOwner.transferAdministrator.selector;
        functionSelectors[3] = IDiamondOwner.owner.selector;
        functionSelectors[4] = IDiamondOwner.admin.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet, 
            action: IDiamondCut.FacetCutAction.Add, 
            functionSelectors: functionSelectors
        });
        LibDiamond.diamondCut(cut, address(0), new bytes(0));

        // adding ERC165 data (done elsewhere)
        //ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        //ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        //ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        //ds.supportedInterfaces[type(IERC173).interfaceId] = true;
    }

    /**
     * @dev Converts a `uint32` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function _toHexDebug(uint32 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        if (facet == address(0)) {
            string memory err = string(abi.encodePacked("NO_DIAMOND_FUNCTION:", _toHexDebug(uint32(msg.sig), 4)));
            revert(err);
        }
        // require(facet != address(0), "Diamond: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    receive() external payable {}
}
