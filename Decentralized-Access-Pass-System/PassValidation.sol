// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

library PassValidation {
    uint256 constant MIN_IPFS_HASH_LENGTH = 44;
    uint256 constant MAX_IPFS_HASH_LENGTH = 62;
    uint256 constant MIN_DURATION = 1 hours;
    uint256 constant MAX_DURATION = 365 days;
    uint256 constant MAX_PASSES_PER_EVENT = 10000;

    function validateIPFSHash(string calldata ipfsHash)
        external
        pure
        returns (bool)
    {
        bytes memory hashBytes = bytes(ipfsHash);
        uint256 length = hashBytes.length;

        if (length < MIN_IPFS_HASH_LENGTH || length > MAX_IPFS_HASH_LENGTH) {
            return false;
        }

        if (length >= 2) {
            if (hashBytes[0] == 0x51 && hashBytes[1] == 0x6d) { // "Qm" in bytes
                return length == 46;
            }
            if (hashBytes[0] == 0x62) { // "b" in bytes
                return length >= 44;
            }
        }
        return false;
    }

    function validateEventParams(
        uint256[3] memory _price,
        uint256 duration,
        uint256[3] memory _maxpass
    ) external pure {
        require(
            duration >= MIN_DURATION && duration <= MAX_DURATION,
            "Invalid duration"
        );
        require(
            _price[0] > 0 && _price[1] > 0 && _price[2] > 0,
            "Invalid prices"
        );

        // Ensure pricing tiers make sense (Basic <= Premium <= VIP)
        require(
            _price[0] <= _price[1] && _price[1] <= _price[2],
            "Invalid price tiers"
        );

        for (uint8 i = 0; i < 3; i++) {
            require(
                _maxpass[i] > 0 && _maxpass[i] <= MAX_PASSES_PER_EVENT,
                "Invalid max passes"
            );
        }
    }

    function isContract(address account) external view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
