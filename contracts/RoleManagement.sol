// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract RoleManagement is AccessControl {
    // Define roles using OpenZeppelin AccessControl
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant POLICY_HOLDER_ROLE = keccak256("POLICY_HOLDER_ROLE");

    // Address lists
    //address[] public admins;
    //address[] public users;

    // Events for role changes
    event AdminAdded(address indexed account);
    event AdminRevoked(address indexed account);
    event UserAdded(address indexed account);
    event UserRevoked(address indexed account);

     constructor(address[] memory initialAdmins) {
      require(initialAdmins.length > 0, "Initial admins array is empty");

      // Assign the deployer as the contract owner and grant them DEFAULT_ADMIN_ROLE and ADMIN_ROLE
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        emit AdminAdded(msg.sender);

        // Assign ADMIN_ROLE to all provided initial admins
        for (uint256 i = 0; i < initialAdmins.length; i++) {
            address admin = initialAdmins[i];
            require(admin != address(0), "Invalid admin address");
            if (!hasRole(ADMIN_ROLE, admin)) {
                _setupRole(ADMIN_ROLE, admin);
                emit AdminAdded(admin);
            }
        }
    }

    // Grants an account the ADMIN_ROLE. @param account Address to be added as an admin.
    function addAdmin(address account) public onlyRole(ADMIN_ROLE) {
        require(account != address(0), "Invalid address");
        require(!hasRole(ADMIN_ROLE, account), "Address is already an admin");
        
        _setupRole(ADMIN_ROLE, account);
        emit AdminAdded(account);
    }

    function revokeAdmin(address account) external onlyRole(ADMIN_ROLE) {
        require(account != address(0), "Invalid address");
        require(hasRole(ADMIN_ROLE, account), "Address is not an admin");

        _revokeRole(ADMIN_ROLE, account);
        emit AdminRevoked(account);
    }

    // Allows a user to register as a POLICY_HOLDER by granting them the POLICY_HOLDER_ROLE.
    function addUser() external {
        address account = msg.sender;
        require(!hasRole(POLICY_HOLDER_ROLE, account), "Address is already a user");

        _setupRole(POLICY_HOLDER_ROLE, account);
        emit UserAdded(account);
    }

    function revokeUser(address account) external onlyRole(ADMIN_ROLE) {
        require(account != address(0), "Invalid address");
        require(hasRole(POLICY_HOLDER_ROLE, account), "Address is not a policy holder");

        _revokeRole(POLICY_HOLDER_ROLE, account);
        emit UserRevoked(account);
    }

    // Checks if an address is an admin.
   function isAdmin(address account) external view returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }

    // Checks if an address is a user (POLICY_HOLDER_ROLE).
    function isUser(address account) external view returns (bool) {
        return hasRole(POLICY_HOLDER_ROLE, account);
    }

    // Returns the role of a given address. The role associated with the address.
    function roleOfAddress(address account) external view returns (string memory role) {
        if (hasRole(ADMIN_ROLE, account)) {
            return "ADMIN_ROLE";
        } else if (hasRole(POLICY_HOLDER_ROLE, account)) {
            return "POLICY_HOLDER_ROLE";
        } else {
            return "NO_ROLE";
        }
    }
}