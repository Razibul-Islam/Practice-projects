// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./PassManagement.sol";

contract AccessPassModifier is Ownable {
    constructor(address initialOwner) Ownable(initialOwner) {}

    using PassManagement for mapping(address => mapping(uint256 => PassManagement.PassData));

    // State variables
    mapping(address => mapping(uint256 => PassManagement.PassData))
        internal userPasses;
    mapping(uint256 => PassManagement.EventData) internal events;
    mapping(address => uint256) internal userPassCount;
    mapping(uint256 => mapping(uint8 => uint256)) internal eventPassCount;
    mapping(uint256 => address[]) internal eventPassHolders;
    mapping(address => bool) internal eventManagers;

    uint256 internal nextEventId;

    // Custom Errors
    error NotAdmin();
    error NotEventManager();
    error InvalidEventId();
    error EventNotActive();
    error PassDoesNotExist();
    error InvalidAddress();
    error InvalidPassType();

    // ============ MODIFIERS ============

    modifier onlyAdmin() {
        if (owner() != msg.sender) revert NotAdmin();
        _;
    }

    modifier onlyEventManager() {
        if (!eventManagers[msg.sender] && owner() != msg.sender) {
            revert NotEventManager();
        }
        _;
    }

    modifier validEvent(uint256 _eventId) {
        if (_eventId == 0 || _eventId >= nextEventId) revert InvalidEventId();
        if (!events[_eventId].active) revert EventNotActive();
        _;
    }

    modifier passExists(address user, uint256 eventId) {
        if (!userPasses[user][eventId].exists) revert PassDoesNotExist();
        _;
    }

    modifier validAddress(address _address) {
        if (_address == address(0)) revert InvalidAddress();
        _;
    }

    modifier validPassType(uint8 passType) {
        if (passType >= 3) revert InvalidPassType();
        _;
    }

    modifier eventExists(uint256 _eventId) {
        if (_eventId == 0 || _eventId >= nextEventId) revert InvalidEventId();
        _;
    }

    modifier validPassTypes(uint8[] memory passTypes) {
        for (uint256 i = 0; i < passTypes.length; i++) {
            if (passTypes[i] >= 3) revert InvalidPassType();
        }
        _;
    }

    modifier validAddresses(address[] memory addresses) {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] == address(0)) revert InvalidAddress();
        }
        _;
    }

    modifier hasActivePass(uint256 eventId) {
        if (!PassManagement.isPassValid(userPasses, msg.sender, eventId)) {
            revert PassDoesNotExist();
        }
        _;
    }

    modifier passIsActive(address user, uint256 eventId) {
        PassManagement.PassData storage pass = userPasses[user][eventId];
        require(
            pass.exists && pass.active && pass.expiry > block.timestamp,
            "Pass not active"
        );
        _;
    }

    modifier validPrices(uint256[3] memory prices) {
        for (uint8 i = 0; i < 3; i++) {
            require(prices[i] > 0, "Price must be greater than 0");
        }
        _;
    }

    modifier validDuration(uint256 duration) {
        require(duration >= 1 days && duration <= 365 days, "Invalid duration");
        _;
    }

    modifier validMaxPasses(uint256[3] memory maxPasses) {
        for (uint8 i = 0; i < 3; i++) {
            require(maxPasses[i] > 0, "Max passes must be greater than 0");
        }
        _;
    }

    // ============ VIEW FUNCTIONS ============

    function isPassValid(address user, uint256 eventId)
        external
        view
        returns (bool)
    {
        return PassManagement.isPassValid(userPasses, user, eventId);
    }

    function getPassExpiry(address user, uint256 eventId)
        external
        view
        passExists(user, eventId)
        returns (uint256)
    {
        return userPasses[user][eventId].expiry;
    }

    function getEventDetails(uint256 eventId)
        external
        view
        eventExists(eventId)
        returns (PassManagement.EventData memory)
    {
        return events[eventId];
    }

    function getPassTypesInfo(uint256 eventId)
        external
        view
        eventExists(eventId)
        returns (PassManagement.PassTypeInfo[3] memory)
    {
        PassManagement.EventData storage ED = events[eventId];
        PassManagement.PassTypeInfo[3] memory passTypes;

        for (uint8 i = 0; i < 3; i++) {
            passTypes[i] = PassManagement.PassTypeInfo({
                name: bytes(ED.passTypeNames[i]).length > 0
                    ? ED.passTypeNames[i]
                    : PassManagement.getPassTypeName(
                        PassManagement.PassType(i)
                    ),
                price: ED.price[i],
                maxPasses: ED.maxPasses[i],
                soldPasses: eventPassCount[eventId][i],
                available: eventPassCount[eventId][i] < ED.maxPasses[i] &&
                    ED.active
            });
        }

        return passTypes;
    }

    function getUserActivePassCount(address user)
        external
        view
        returns (uint256)
    {
        return
            PassManagement.getUserActivePassCount(
                userPasses,
                user,
                nextEventId
            );
    }

    function getUserPasses(address user)
        external
        view
        validAddress(user)
        returns (PassManagement.UserPassDetails[] memory)
    {
        // Count active passes first
        uint256 activePassCount = 0;
        for (uint256 i = 1; i < nextEventId; i++) {
            if (userPasses[user][i].exists) {
                activePassCount++;
            }
        }

        // Create array to return
        PassManagement.UserPassDetails[] memory passes = new PassManagement.UserPassDetails[](
            activePassCount
        );
        uint256 index = 0;

        // Populate the array
         for (uint256 i = 1; i < nextEventId; i++) {
            if (userPasses[user][i].exists) {
                PassManagement.PassData storage pass = userPasses[user][i];
                passes[index] = PassManagement.UserPassDetails({
                    eventId: i,
                    accessLevel: pass.accessLevel,
                    expiry: pass.expiry,
                    active: pass.active,
                    exists: pass.exists,
                    purchaseTime: pass.purchaseTime
                });
                index++;
            }
        }

        return passes;
    }

    // Additional view functions can be added here as needed
}
