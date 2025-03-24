// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { LibDiamond } from "../libraries/LibDiamond.sol";

contract SimpleFacets {
   
    function incrementCounter() external {
        LibDiamond.incrementCounter();
    }
    
    function getCounter(address _user) external view returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.userTransactions[_user];
    }
    
    function getTotalTransactions() external view returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.totalTransactions;
    }

    function addCredits(address user, uint256 amount) external {
        LibDiamond.addCredits(user, amount);
    }

    function removeCredits(address user, uint amount) external {
        LibDiamond.removeCredits(user, amount);
    }

    function getUserCredits(address user) external view returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.userCredits[user];
    }

    function setUserWhitelist(address user, bool status) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.userWhitelisted[user] = status;
        
    }

    function setUserNote(address user, string calldata note) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.userNotes[user] = note;
       
    }

     function isUserWhitelisted(address user) external view returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.userWhitelisted[user];
    }

    function getUserNote(address user) external view returns (string memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.userNotes[user];
    }

    
}