// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract RoleManagement is AccessControl {
    // Define roles
    bytes32 public constant POLICY_ADMIN_ROLE = keccak256("POLICY_ADMIN_ROLE");
    bytes32 public constant PREMIUM_ADMIN_ROLE = keccak256("PREMIUM_ADMIN_ROLE");

    // Constructor: Assign DEFAULT_ADMIN_ROLE to deployer
    constructor() {
        grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Grant role (only Admin can grant roles)
    function grantRoleTo(bytes32 role, address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(role, account);
    }

    // Revoke role (only Admin can revoke roles)
    function revokeRoleFrom(bytes32 role, address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(role, account);
    }

    // Check if account has role
    function hasRoleAccess(bytes32 role, address account) external view returns (bool) {
        return hasRole(role, account);
    }
}