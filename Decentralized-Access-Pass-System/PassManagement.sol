// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

library PassManagement {
    enum PassType { BASIC, PREMIUM, VIP }
    
    struct PassData {
        bool active;
        uint256 expiry;
        uint256 eventId;
        PassType accessLevel;
        bool exists;
        uint256 purchaseTime;
    }

    struct EventData {
        uint256[3] price;
        uint256 duration;
        uint256[3] maxPasses;
        string ipfsHash;
        bool active;
        string eventName;
        string[3] passTypeNames;
    }

    struct PassTypeInfo {
        string name;
        uint256 price;
        uint256 maxPasses;
        uint256 soldPasses;
        bool available;
    }

      struct UserPassDetails {
        uint256 eventId;
        PassManagement.PassType accessLevel;
        uint256 expiry;
        bool active;
        bool exists;
        uint256 purchaseTime;
    }

    function createPass(
        mapping(address => mapping(uint256 => PassData)) storage userPasses,
        mapping(uint256 => address[]) storage eventPassHolders,
        mapping(address => uint256) storage userPassCount,
        mapping(uint256 => mapping(uint8 => uint256)) storage eventPassCount,
        address user,
        uint256 eventId,
        uint8 passType,
        uint256 duration
    ) external {
        uint256 expiryTime = block.timestamp + duration;

        userPasses[user][eventId] = PassData({
            active: true,
            expiry: expiryTime,
            eventId: eventId,
            accessLevel: PassType(passType),
            exists: true,
            purchaseTime: block.timestamp
        });

        eventPassHolders[eventId].push(user);
        userPassCount[user]++;
        eventPassCount[eventId][passType]++;
    }

    function isPassValid(
        mapping(address => mapping(uint256 => PassData)) storage userPasses,
        address user,
        uint256 eventId
    ) external view returns (bool) {
        PassData storage pass = userPasses[user][eventId];
        return pass.exists && pass.active && pass.expiry > block.timestamp;
    }

    function getUserActivePassCount(
        mapping(address => mapping(uint256 => PassData)) storage userPasses,
        address user,
        uint256 nextEventId
    ) external view returns (uint256) {
        uint256 activeCount = 0;
        for (uint256 i = 1; i < nextEventId; i++) {
            PassData storage pass = userPasses[user][i];
            if (pass.exists && pass.active && pass.expiry > block.timestamp) {
                activeCount++;
            }
        }
        return activeCount;
    }

    function getPassTypeName(PassType passType) external pure returns (string memory) {
        if (passType == PassType.BASIC) return "Basic";
        if (passType == PassType.PREMIUM) return "Premium";
        if (passType == PassType.VIP) return "VIP";
        return "Unknown";
    }
}