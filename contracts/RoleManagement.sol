// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract RoleManagement is AccessControl {
    // Define roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant POLICY_HOLDER_ROLE = keccak256("POLICY_HOLDER_ROLE");

    // Address lists
    address[] public admins;
    address[] public users;

    // Events for debugging
    event AdminAdded(address indexed account);
    event UserAdded(address indexed account);

     constructor(address[] memory initialAdmins) {
      require(initialAdmins.length > 0, "Initial admins array is empty");
        _grantRole(ADMIN_ROLE, msg.sender);
        admins.push(msg.sender);
        emit AdminAdded(msg.sender);

        // Assign ADMIN_ROLE to all initialAdmins
        for (uint256 i = 0; i < initialAdmins.length; i++) {
          require(initialAdmins[i] != address(0), "Invalid admin address");
            if (!_isInList(admins, initialAdmins[i])) {
                _grantRole(ADMIN_ROLE, initialAdmins[i]);
                admins.push(initialAdmins[i]);
                emit AdminAdded(initialAdmins[i]);
            }
        }
    }

    // Add an address to the admins list (only Admins can call this function)
    function addAdmin(address account) public onlyRole(ADMIN_ROLE) {
        require(!_isInList(admins, account), "Address is already an admin");
        _grantRole(ADMIN_ROLE, account);
        admins.push(account);
         emit AdminAdded(account);
    }

    // Add an address to the users list
    function addUser(address account) public {
        require(!_isInList(users, account), "Address is already a user");
        require(account == msg.sender, "You can only register your own wallet address");
        _grantRole(POLICY_HOLDER_ROLE, account);
        users.push(account);
        emit UserAdded(account);
    }

    // Utility function to remove an address from a list
    function _removeFromList(address[] storage list, address account) internal {
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i] == account) {
                list[i] = list[list.length - 1]; // Replace with last element
                list.pop(); // Remove last element
                break;
            }
        }
    }

    // Check if an address is in the list
    function _isInList(address[] storage list, address account) internal view returns (bool) {
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i] == account) {
                return true;
            }
        }
        return false;
    }

    // Check if an address is in the admins list
    function _isInAdmins(address account) external view returns (bool) {
        return _isInList(admins, account);
    }

    // Check if an address is in the users list
    function _isInUsers(address account) external view returns (bool) {
        return _isInList(users, account);
    }

    // Get the role of a specific address
    function roleOfAddress(address account) public view returns (address, string memory) {
        if (hasRole(ADMIN_ROLE, account)) {
            return (account, "ADMIN_ROLE");
        } else if (hasRole(POLICY_HOLDER_ROLE, account)) {
            return (account, "POLICY_HOLDER_ROLE");
        } else {
            return (account, "NO_ROLE");
        }
    }
}