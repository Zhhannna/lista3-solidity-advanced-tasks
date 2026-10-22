
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract UserRegistry {

    struct User {
        string name;
        uint age;
    }

    // Permanent list of users in storage
    User[] public users;

    // Add a user
    function addUser(
        string calldata name,
        uint age
    ) external {
        users.push(User(name, age));
    }

    // Update a user's name
    function updateUser(
        uint index,
        string memory newName
    ) external {
        require(index < users.length, "Invalid user index");
        users[index].name = newName;
    }

    // Return all users
    function getUsers()
        external
        view
        returns (User[] memory)
    {
        return users;
    }

    // Modify a temporary copy without changing storage
    function getModifiedCopy(
        uint index,
        string memory temporaryName
    ) external view returns (string memory) {
        require(index < users.length, "Invalid user index");

        User memory copiedUser = users[index];
        copiedUser.name = temporaryName;

        return copiedUser.name;
    }
}

contract ReentrancyGuardTransient {

    mapping(address => uint256) public balances;

    // Unique transient-storage slot for the lock
    bytes32 private constant LOCK_SLOT =
        keccak256("ReentrancyGuardTransient.lock");

    error ReentrantCall();
    error NoBalance();
    error TransferFailed();

    // Deposit ETH and record the sender's balance
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    // Withdraw the caller's entire balance safely
    function secureWithdraw() external {
        bytes32 slot = LOCK_SLOT;
        bool alreadyLocked;

        // Check whether the lock is active
        assembly {
            alreadyLocked := tload(slot)
        }

        if (alreadyLocked) {
            revert ReentrantCall();
        }

        // Activate the transient lock
        assembly {
            tstore(slot, 1)
        }

        uint256 amount = balances[msg.sender];

        if (amount == 0) {
            revert NoBalance();
        }

        // Update state before transferring ETH
        balances[msg.sender] = 0;

        (bool success, ) =
            payable(msg.sender).call{value: amount}("");

        if (!success) {
            revert TransferFailed();
        }

        // Release the transient lock
        assembly {
            tstore(slot, 0)
        }
    }

    // Return the ETH held by this contract
    function contractBalance()
        external
        view
        returns (uint256)
    {
        return address(this).balance;
    }
}

contract MathOperations {
    function add(uint a, uint b) public pure returns (uint) {
        return a + b;
    }

    function subtract(uint a, uint b) public pure returns (uint) {
        require(a >= b, "Result cannot be negative");
        return a - b;
    }

    function multiply(uint a, uint b) public pure returns (uint) {
        return a * b;
    }

    function divide(uint a, uint b) public pure returns (uint) {
        require(b != 0, "Cannot divide by zero");
        return a / b;
    }

    function square(uint a) internal pure returns (uint) {
        return a * a;
    }

    function squareNumber(uint a) external pure returns (uint) {
        return square(a);
    }

    function privateDouble(uint a) private pure returns (uint) {
        return a * 2;
    }

    function getDouble(uint a) external pure returns (uint) {
        return privateDouble(a);
    }
}

contract BankAnalytics {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    function getTotalBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function calculateInterest(uint256 amount, uint256 ratePercent)
        external
        pure
        returns (uint256)
    {
        return (amount * ratePercent) / 100;
    }

    function canWithdraw(address user, uint256 amount)
        external
        view
        returns (bool)
    {
        return balances[user] >= amount;
    }
}

contract SecureVault {
    address public owner;
    mapping(address => uint256) public balances;

    error NotOwner();
    error InsufficientBalance();
    error ZeroDeposit();
    error TransferFailed();

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    modifier hasBalance(uint256 amount) {
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance();
        }
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
        if (msg.value == 0) {
            revert ZeroDeposit();
        }

        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount)
        external
        hasBalance(amount)
    {
        balances[msg.sender] -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");

        if (!success) {
            revert TransferFailed();
        }
    }

    function emergencyWithdraw(address payable recipient)
        external
        onlyOwner
    {
        uint256 amount = address(this).balance;

        (bool success, ) = recipient.call{value: amount}("");

        if (!success) {
            revert TransferFailed();
        }
    }

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
