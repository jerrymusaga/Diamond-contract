// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "forge-std/Test.sol";
import "../contracts/Diamond.sol";
import "../contracts/facets/SimpleFacets.sol"; 
import "../contracts/facets/SimpleFacets2.sol";

contract DiamondDeployer is Test, IDiamondCut {
    Diamond public diamond;
    DiamondCutFacet public dCutFacet;
    DiamondLoupeFacet public dLoupe;
    OwnershipFacet public ownerF;
    SimpleFacets public simpleFacet; 
    SimpleFacets2 public simpleFacets2;

    function generateSelectors(string memory _facetName) internal returns (bytes4[] memory) {
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[1] = "scripts/genSelectors.js";
        cmd[2] = _facetName;
        bytes memory res = vm.ffi(cmd);
        return abi.decode(res, (bytes4[]));
    }

    function setUp() public {
      
        dCutFacet = new DiamondCutFacet();
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        simpleFacet = new SimpleFacets();
        simpleFacets2 = new SimpleFacets2();

        diamond = new Diamond(address(this), address(dCutFacet));

        // Create an array for our facet cuts
        FacetCut[] memory cut = new FacetCut[](4);

        // Add DiamondLoupeFacet
        cut[0] = FacetCut({
            facetAddress: address(dLoupe),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("DiamondLoupeFacet")
        });

        // Add OwnershipFacet
        cut[1] = FacetCut({
            facetAddress: address(ownerF),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("OwnershipFacet")
        });

        // Add SimpleFacet
        cut[2] = FacetCut({
            facetAddress: address(simpleFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("SimpleFacets")
        });

        cut[3] = FacetCut({
            facetAddress: address(simpleFacets2),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("SimpleFacets2")
        });

        // Make the diamondCut call
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");
    }

    function testDeployDiamond() public {
        // Verify facets were added
        address[] memory facets = DiamondLoupeFacet(address(diamond)).facetAddresses();
        assertEq(facets.length, 4); // Diamond + 3 facets
    }

    function testSimpleFacetIncrementFunctionality() public {
        address user1 = address(0x1);
        address user2 = address(0x2);

        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        
      
        assertEq(SimpleFacets(address(diamond)).getCounter(user1), 0);
        assertEq(SimpleFacets(address(diamond)).getTotalTransactions(), 0);
     
        vm.prank(user1);
        SimpleFacets(address(diamond)).incrementCounter();
        
       
        assertEq(SimpleFacets(address(diamond)).getCounter(user1), 1);
        assertEq(SimpleFacets(address(diamond)).getTotalTransactions(), 1);
        
     
        vm.prank(user2);
        SimpleFacets(address(diamond)).incrementCounter();
        
        
        assertEq(SimpleFacets(address(diamond)).getCounter(user1), 1);
        assertEq(SimpleFacets(address(diamond)).getCounter(user2), 1);
        assertEq(SimpleFacets(address(diamond)).getTotalTransactions(), 2);
    }

    function testMultipleSimpleFacetsIncrements() public {
        address user1 = address(0x1);
        address user2 = address(0x2);

        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        for (uint i = 0; i < 5; i++) {
            vm.prank(user1);
            SimpleFacets(address(diamond)).incrementCounter();
        }
        
        assertEq(SimpleFacets(address(diamond)).getCounter(user1), 5);
        assertEq(SimpleFacets(address(diamond)).getTotalTransactions(), 5);
    }

    function testAddCredits() public {
        address user1 = address(0x1);
        address user2 = address(0x2);

        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        assertEq(SimpleFacets(address(diamond)).getUserCredits(user1), 0);
        
        
        vm.prank(user1);
        SimpleFacets(address(diamond)).addCredits(user1, 100);
        
      
        assertEq(SimpleFacets(address(diamond)).getUserCredits(user1), 100);
        
       
        vm.prank(user1);
        SimpleFacets(address(diamond)).addCredits(user1, 50);
        
        
        assertEq(SimpleFacets(address(diamond)).getUserCredits(user1), 150);
    }
    
    function testRemoveCredits() public {
        address user1 = address(0x1);
        vm.prank(user1);
        SimpleFacets(address(diamond)).addCredits(user1, 100);
        
       
        vm.prank(user1);
        SimpleFacets(address(diamond)).removeCredits(user1, 30);
        
      
        assertEq(SimpleFacets(address(diamond)).getUserCredits(user1), 70);
        

        vm.prank(user1);
        vm.expectRevert("Not enough credits");
        SimpleFacets(address(diamond)).removeCredits(user1, 100);
    }

    function testSetUserWhitelist() public {
        address owner = address(0x2);
        address user1 = address(0x1);
        assertEq(SimpleFacets(address(diamond)).isUserWhitelisted(user1), false);
        
    
        vm.prank(owner);
        SimpleFacets(address(diamond)).setUserWhitelist(user1, true);
        
   
        assertEq(SimpleFacets(address(diamond)).isUserWhitelisted(user1), true);
        
      
        vm.prank(owner);
        SimpleFacets(address(diamond)).setUserWhitelist(user1, false);
        
        
        assertEq(SimpleFacets(address(diamond)).isUserWhitelisted(user1), false);
    }
    
    function testSetUserNote() public {
        address user1 = address(0x1);
        address owner = address(0x2);
        string memory testNote = "my notes for test";
        
      
        assertEq(SimpleFacets(address(diamond)).getUserNote(user1), "");
        
   
        vm.prank(owner);
        SimpleFacets(address(diamond)).setUserNote(user1, testNote);
        
     
        assertEq(SimpleFacets(address(diamond)).getUserNote(user1), testNote);
    }

    function testClaimReward() public {
        address user1 = address(0x1);
        vm.prank(user1);
        SimpleFacets(address(diamond)).addCredits(user1, 100);
        
        uint256 initialCredits = SimpleFacets(address(diamond)).getUserCredits(user1);
        uint256 claimAmount = 50;
        
        vm.prank(user1);
        SimpleFacets2(address(diamond)).claimReward(claimAmount);
        
        assertEq(SimpleFacets(address(diamond)).getUserCredits(user1), initialCredits - claimAmount);
        
        vm.prank(user1);
        SimpleFacets2(address(diamond)).claimReward(10);
    }

    
    function testUpdateUserLevel() public {
        address user1 = address(0x1);
        address owner = address(this);
        
        uint256 newLevel = 3;
        vm.prank(owner);
        SimpleFacets2(address(diamond)).updateUserLevel(user1, newLevel);
        
        assertEq(SimpleFacets2(address(diamond)).getUserLevel(user1), newLevel);
        
       
        vm.prank(owner);
        vm.expectRevert("Invalid level");
        SimpleFacets2(address(diamond)).updateUserLevel(user1, 0);
        
        vm.prank(owner);
        vm.expectRevert("Invalid level");
        SimpleFacets2(address(diamond)).updateUserLevel(user1, 11);
    }

    
    function testMakeDeposit() public {
        address user1 = address(0x1);
        uint256 depositAmount = 100;
        
        vm.prank(user1);
        SimpleFacets2(address(diamond)).makeDeposit(depositAmount);
        
        assertEq(SimpleFacets(address(diamond)).getUserCredits(user1), depositAmount);
        assertEq(SimpleFacets2(address(diamond)).getTotalDeposits(), depositAmount);
        
        
        vm.prank(user1);
        SimpleFacets2(address(diamond)).makeDeposit(50);
    }

   
    function testMakeWithdrawal() public {
        address user1 = address(0x1);
        uint256 initialAmount = 100;
        uint256 withdrawAmount = 30;
        
        vm.prank(user1);
        SimpleFacets2(address(diamond)).makeDeposit(initialAmount);
        
        vm.prank(user1);
        SimpleFacets2(address(diamond)).makeWithdrawal(withdrawAmount);
        
        assertEq(SimpleFacets(address(diamond)).getUserCredits(user1), initialAmount - withdrawAmount);
        

        vm.prank(user1);
        vm.expectRevert("Insufficient balance");
        SimpleFacets2(address(diamond)).makeWithdrawal(initialAmount * 2);
    }

    
    function testUpdateSetting() public {
        address owner = address(this);
        bytes32 settingName = keccak256("MAX_LIMIT");
        uint256 settingValue = 500;
        
        vm.prank(owner);
        SimpleFacets2(address(diamond)).updateSetting(settingName, settingValue);
        
        assertEq(SimpleFacets2(address(diamond)).getSetting(settingName), settingValue);
        
      
        vm.prank(owner);
        vm.expectRevert("Value must > 0");
        SimpleFacets2(address(diamond)).updateSetting(settingName, 0);
    }


    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}


