// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    error InValidFacetCutAction();
    error NotDiamondOwner();
    error NoSelectorsInFacet();
    error NoZeroAddress();
    error SelectorExists(bytes4 selector);
    error SameSelectorReplacement(bytes4 selector);
    error MustBeZeroAddress();
    error NoCode();
    error NonExistentSelector(bytes4 selector);
    error ImmutableFunction(bytes4 selector);
    error NonEmptyCalldata();
    error EmptyCalldata();
    error InitCallFailed();
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;


        // My storage
        uint256 totalTransactions;
        mapping(address => uint256) userTransactions;
        mapping(address => uint256) userCredits;
        mapping(address => bool) userWhitelisted;
        mapping(address => string) userNotes;

        uint totalDeposits;
        mapping(address => uint256) userLevels;
        mapping(bytes32 => uint256) settings;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        if (msg.sender != diamondStorage().contractOwner)
            revert NotDiamondOwner();
    }

    // My New Functions
    event CounterIncremented(address user, uint256 newCount);
    function incrementCounter() internal {
        DiamondStorage storage ds = diamondStorage();
        ds.totalTransactions++;
        ds.userTransactions[msg.sender]++;

        emit CounterIncremented(msg.sender, ds.userTransactions[msg.sender]);
    }

    function getCounter(address _user) internal view returns (uint256) {
        DiamondStorage storage ds = diamondStorage();
        return ds.userTransactions[_user];
    }

    function getTotalTransactions() internal view returns (uint256) {
        DiamondStorage storage ds = diamondStorage();
        return ds.totalTransactions;
    }


    event CreditsAdded(address user, uint256 amount);
    event CreditsRemoved(address user, uint256 amount);

    function addCredits(address user, uint256 amount) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.userCredits[user] += amount;
        
        emit CreditsAdded(user, amount);
    }

    function removeCredits(address user, uint256 amount) internal {
        DiamondStorage storage ds = diamondStorage();
        require(ds.userCredits[user] >= amount, "Not enough credits");
        ds.userCredits[user] -= amount;
        
        emit CreditsRemoved(user, amount);
    }

    function getUserCredits(address user) external view returns (uint256) {
        DiamondStorage storage ds = diamondStorage();
        return ds.userCredits[user];
    }

    event UserWhitelisted(address user, bool status);
    event UserNoteUpdated(address user, string note);

    function setUserWhitelist(address user, bool status) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.userWhitelisted[user] = status;
        
        emit UserWhitelisted(user, status);
    }

    
    function setUserNote(address user, string calldata note) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.userNotes[user] = note;
        
        emit UserNoteUpdated(user, note);
    }

    function isUserWhitelisted(address user) external view returns (bool) {
        DiamondStorage storage ds = diamondStorage();
        return ds.userWhitelisted[user];
    }
    
    function getUserNote(address user) external view returns (string memory) {
        DiamondStorage storage ds = diamondStorage();
        return ds.userNotes[user];
    }

    event RewardClaimed(address user, uint256 amount);
    event UserLevelUpdated(address user, uint256 level);
    event DepositMade(address user, uint256 amount);
    event WithdrawalMade(address user, uint256 amount);
    event SettingsUpdated(bytes32 setting, uint256 value);

     function claimReward(uint256 amount) internal {
        DiamondStorage storage ds = diamondStorage();
        require(ds.userCredits[msg.sender] >= amount, "Insufficient credits");
        require(amount > 0, "Amount must be positive");
        
        ds.userCredits[msg.sender] -= amount;
        emit RewardClaimed(msg.sender, amount);
    }

    function updateUserLevel(address user, uint256 level) internal {
        DiamondStorage storage ds = diamondStorage();
        require(level > 0 && level <= 10, "Invalid level");
        
        ds.userLevels[user] = level;
        emit UserLevelUpdated(user, level);
    }

    
    function makeDeposit(uint256 amount) internal {
        DiamondStorage storage ds = diamondStorage();
        require(amount > 0, "amount must > 0");
        
        ds.totalDeposits += amount; 
        ds.userCredits[msg.sender] += amount;
        emit DepositMade(msg.sender, amount);
    }

    
    function makeWithdrawal(uint256 amount) internal {
        DiamondStorage storage ds = diamondStorage();
        require(amount > 0, "Amount must > 0");
        require(ds.userCredits[msg.sender] >= amount, "Insufficient balance");
        
        ds.userCredits[msg.sender] -= amount;
        emit WithdrawalMade(msg.sender, amount);
    }

   
    function updateSetting(bytes32 setting, uint256 value) internal {
        DiamondStorage storage ds = diamondStorage();
        require(value > 0, "Value must > 0");
        
        ds.settings[setting] = value;
        emit SettingsUpdated(setting, value);
    }

    
    function getUserLevel(address user) external view returns (uint256) {
        DiamondStorage storage ds = diamondStorage();
        return ds.userLevels[user];
    }

    function getTotalDeposits() external view returns (uint256) {
        DiamondStorage storage ds = diamondStorage();
        return ds.totalDeposits;
    }

    function getSetting(bytes32 setting) external view returns (uint256) {
        DiamondStorage storage ds = diamondStorage();
        return ds.settings[setting];
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert InValidFacetCutAction();
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
        DiamondStorage storage ds = diamondStorage();
        if (_facetAddress == address(0)) revert NoZeroAddress();
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            if (oldFacetAddress != address(0)) revert SelectorExists(selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
        DiamondStorage storage ds = diamondStorage();
        if (_facetAddress == address(0)) revert NoZeroAddress();
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            if (oldFacetAddress == _facetAddress)
                revert SameSelectorReplacement(selector);
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        if (_facetAddress != address(0)) revert MustBeZeroAddress();
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(
        DiamondStorage storage ds,
        address _facetAddress
    ) internal {
        enforceHasContractCode(_facetAddress);
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        if (_facetAddress == address(0)) revert NonExistentSelector(_selector);
        // an immutable function is a function defined directly in a diamond
        if (_facetAddress == address(this)) revert ImmutableFunction(_selector);
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(
        address _init,
        bytes memory _calldata
    ) internal {
        if (_init == address(0)) {
            if (_calldata.length > 0) revert NonEmptyCalldata();
        } else {
            if (_calldata.length == 0) revert EmptyCalldata();
            if (_init != address(this)) {
                enforceHasContractCode(_init);
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert InitCallFailed();
                }
            }
        }
    }

    function enforceHasContractCode(address _contract) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize <= 0) revert NoCode();
    }
}
