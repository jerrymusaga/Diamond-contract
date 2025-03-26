// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { LibDiamond } from "../libraries/LibDiamond.sol";

contract SimpleFacets2 {
   
   modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    
    function claimReward(uint256 amount) external {
        LibDiamond.claimReward(amount);   
    }

   
    function updateUserLevel(address user, uint256 level) external onlyOwner {
        LibDiamond.updateUserLevel(user, level);    
    }

    
    function makeDeposit(uint256 amount) external {
        LibDiamond.makeDeposit(amount);    
    }

    
    function makeWithdrawal(uint256 amount) external {
        LibDiamond.makeWithdrawal(amount); 
    }

    
    function updateSetting(bytes32 setting, uint256 value) external onlyOwner {
        LibDiamond.updateSetting(setting, value);
    }

    function getUserLevel(address user) external view returns (uint256) {
        return LibDiamond.getUserLevel(user);
    }

    function getTotalDeposits() external view returns (uint256) {
        return LibDiamond.getTotalDeposits();
    }

    function getSetting(bytes32 setting) external view returns (uint256) {
        return LibDiamond.getSetting(setting);
    }

}