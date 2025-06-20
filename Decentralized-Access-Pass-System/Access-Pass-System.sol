// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./PassValidation.sol";
import "./PassManagement.sol";
import "./Access-Pass-System-Modifiers.sol";

contract AccessPassSystem is AccessPassModifier, ReentrancyGuard {
    using PassManagement for mapping(address => mapping(uint256 => PassManagement.PassData));
    using PassValidation for string;

    IERC20 public paymentToken;
    address public treasury;

    // Events
    event PassCreated(
        address indexed user,
        uint256 indexed eventId,
        PassManagement.PassType passType,
        uint256 expiry,
        uint256 price
    );
    event PassExtended(
        address indexed user,
        uint256 indexed eventId,
        uint256 newExpiry
    );
    event PassRevoked(address indexed user, uint256 indexed eventId);
    event PassRenewed(
        address indexed user,
        uint256 indexed eventId,
        uint256 newExpiry
    );
    event EventCreated(
        uint256 indexed eventId,
        string eventName,
        uint256[3] prices,
        uint256[3] maxPasses,
        string ipfsHash
    );
    event EventUpdated(
        uint256 indexed eventId,
        uint256[3] newPrice,
        uint256 newDuration,
        uint256[3] newMaxPasses
    );
    event EventDeactivated(uint256 indexed eventId);
    event PaymentReceived(
        address indexed user,
        uint256 amount,
        uint256 indexed eventId,
        PassManagement.PassType passType
    );
    event PaymentTokenChanged(address oldToken, address newToken);
    event PaymentWithdrawn(address indexed recipient, uint256 value);
    event EventManagerAdded(address indexed manager);
    event EventManagerRemoved(address indexed manager);
    event TreasuryUpdated(
        address indexed oldTreasury,
        address indexed newTreasury
    );

    constructor(address _paymentToken, address _treasury)
        AccessPassModifier(msg.sender)
        validAddress(_paymentToken)
        validAddress(_treasury)
    {
        paymentToken = IERC20(_paymentToken);
        treasury = _treasury;
        nextEventId = 1;
    }

    // Admin Functions
    function createEvent(
        string calldata eventName,
        uint256[3] memory _price,
        uint256 duration,
        uint256[3] memory _maxpass,
        string calldata ipfsHash,
        string[3] calldata passTypeNames
    ) external onlyAdmin {
        PassValidation.validateEventParams(_price, duration, _maxpass);
        require(PassValidation.validateIPFSHash(ipfsHash), "Invalid IPFS hash");
        require(bytes(eventName).length > 0, "Event name required");

        events[nextEventId] = PassManagement.EventData({
            price: _price,
            duration: duration,
            maxPasses: _maxpass,
            ipfsHash: ipfsHash,
            active: true,
            eventName: eventName,
            passTypeNames: passTypeNames
        });

        emit EventCreated(nextEventId, eventName, _price, _maxpass, ipfsHash);
        nextEventId++;
    }

    function updateEvent(
        uint256 eventId,
        uint256[3] memory _price,
        uint256 _duration,
        uint256[3] memory _maxpasses
    ) external onlyAdmin validEvent(eventId) {
        PassManagement.EventData storage ED = events[eventId];
        PassValidation.validateEventParams(_price, _duration, _maxpasses);

        for (uint8 i = 0; i < 3; i++) {
            require(
                _maxpasses[i] >= eventPassCount[eventId][i],
                "Max passes below current sold"
            );
        }

        ED.price = _price;
        ED.duration = _duration;
        ED.maxPasses = _maxpasses;

        emit EventUpdated(eventId, _price, _duration, _maxpasses);
    }

    function deactivateEvent(uint256 eventId)
        external
        onlyAdmin
        validEvent(eventId)
    {
        events[eventId].active = false;
        emit EventDeactivated(eventId);
    }

    function revokePass(address user, uint256 eventId)
        external
        onlyAdmin
        validEvent(eventId)
        passExists(user, eventId)
    {
        PassManagement.PassData storage pass = userPasses[user][eventId];
        require(pass.active, "Pass already deactivated");

        pass.active = false;
        if (userPassCount[user] > 0) userPassCount[user]--;
        if (eventPassCount[eventId][uint8(pass.accessLevel)] > 0) {
            eventPassCount[eventId][uint8(pass.accessLevel)]--;
        }

        emit PassRevoked(user, eventId);
    }

    function extendPass(
        address user,
        uint256 eventId,
        uint256 additionalTime
    ) external passExists(user, eventId) validEvent(eventId) onlyAdmin {
        PassManagement.PassData storage pass = userPasses[user][eventId];
        require(pass.active, "Pass is not active");
        require(
            additionalTime > 0 && additionalTime <= 365 days,
            "Invalid additional time"
        );

        pass.expiry = pass.expiry > block.timestamp
            ? pass.expiry + additionalTime
            : block.timestamp + additionalTime;

        emit PassExtended(user, eventId, pass.expiry);
    }

    function setPaymentToken(address tokenAddress)
        external
        onlyAdmin
        validAddress(tokenAddress)
    {
        require(
            PassValidation.isContract(tokenAddress),
            "Not a contract address"
        );
        address oldToken = address(paymentToken);
        paymentToken = IERC20(tokenAddress);
        emit PaymentTokenChanged(oldToken, tokenAddress);
    }

    function setTreasury(address _treasury)
        external
        onlyAdmin
        validAddress(_treasury)
    {
        address oldTreasury = treasury;
        treasury = _treasury;
        emit TreasuryUpdated(oldTreasury, _treasury);
    }

    function addEventManager(address manager)
        external
        onlyAdmin
        validAddress(manager)
    {
        eventManagers[manager] = true;
        emit EventManagerAdded(manager);
    }

    function removeEventManager(address manager) external onlyAdmin {
        eventManagers[manager] = false;
        emit EventManagerRemoved(manager);
    }

    function withdrawFunds() external onlyAdmin {
        uint256 balance = paymentToken.balanceOf(address(this));
        require(balance > 0, "Insufficient balance");
        require(paymentToken.transfer(treasury, balance), "Transfer failed");
        emit PaymentWithdrawn(treasury, balance);
    }

    // User Functions
    function purchasePass(uint256 eventId, uint8 passType)
        external
        validEvent(eventId)
        validPassType(passType)
        nonReentrant
    {
        PassManagement.EventData storage ED = events[eventId];

        require(
            eventPassCount[eventId][passType] < ED.maxPasses[passType],
            "Pass type sold out"
        );
        require(!userPasses[msg.sender][eventId].exists, "Pass already exists");

        uint256 price = ED.price[passType];
        _validatePayment(price);

        PassManagement.createPass(
            userPasses,
            eventPassHolders,
            userPassCount,
            eventPassCount,
            msg.sender,
            eventId,
            passType,
            ED.duration
        );

        emit PassCreated(
            msg.sender,
            eventId,
            PassManagement.PassType(passType),
            block.timestamp + ED.duration,
            price
        );
        emit PaymentReceived(
            msg.sender,
            price,
            eventId,
            PassManagement.PassType(passType)
        );
    }

    function renewPass(uint256 eventId)
        external
        validEvent(eventId)
        passExists(msg.sender, eventId)
        nonReentrant
    {
        PassManagement.PassData storage pass = userPasses[msg.sender][eventId];
        PassManagement.EventData storage ED = events[eventId];

        require(
            !pass.active || pass.expiry <= block.timestamp,
            "Pass is still active"
        );

        uint256 price = ED.price[uint8(pass.accessLevel)];
        _validatePayment(price);

        pass.active = true;
        pass.expiry = block.timestamp + ED.duration;

        emit PassRenewed(msg.sender, eventId, pass.expiry);
        emit PaymentReceived(msg.sender, price, eventId, pass.accessLevel);
    }

    // Internal Functions
    function _validatePayment(uint256 amount) internal {
        uint256 allowance = paymentToken.allowance(msg.sender, address(this));
        require(allowance >= amount, "Insufficient allowance");

        uint256 balance = paymentToken.balanceOf(msg.sender);
        require(balance >= amount, "Insufficient balance");

        require(
            paymentToken.transferFrom(msg.sender, address(this), amount),
            "Payment transfer failed"
        );
    }

    // Additional view functions
    function getContractBalance() external view returns (uint256) {
        return paymentToken.balanceOf(address(this));
    }
}
