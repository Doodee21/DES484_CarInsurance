// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PolicyManagement.sol";
import "./RoleManagement.sol";

contract PremiumCollection {
    RoleManagement private roleManagement;
    PolicyManagement private policyManagement;

    struct Premium {
        uint256 indexUserPolicy; // Index of policy selected by user
        uint256 policyPremium;  // Premium of that's Policy
    }

    mapping(address => Premium[]) private userPremiums;
    mapping(uint256 => uint256) private premiumsPaid;
    uint256 private poolBalance;

    event PremiumPaid(uint256 policyId, uint256 amount);
    event PoolBalanceUpdated(uint256 newBalance);
    event UserPremiumSet(address indexed user, uint256 policyIndex, uint256 premium);

    constructor(address _roleManagementAddress, address _policyManagementAddress) {
        roleManagement = RoleManagement(_roleManagementAddress);
        policyManagement = PolicyManagement(_policyManagementAddress);
    }

    function setUserPremium(address user, uint256 policyIndex, uint256 policyPremium) public {
    require(
        roleManagement._isInAdmins(msg.sender),
        "Access denied: You are not Admin"
    );
    require(roleManagement._isInUsers(user), "Invalid user address");
    require(policyPremium > 0, "Premium must be greater than zero");

    uint256[] memory userPolicies = policyManagement.getUserPolicies(user);
    require(policyIndex <= userPolicies.length, "Invalid policy index");

    Premium[] storage premiums = userPremiums[user];
    for (uint256 i = 0; i < premiums.length; i++) {
        require(
            premiums[i].indexUserPolicy != policyIndex,
            "Premium already set for this policy index"
        );
    }

    premiums.push(Premium({
        indexUserPolicy: policyIndex,
        policyPremium: policyPremium
    }));

    emit UserPremiumSet(user, policyIndex, policyPremium);
}

    function getUserPremium(address user, uint256 policyIndex) public view returns (uint256) {
        require(
            roleManagement._isInUsers(msg.sender) || roleManagement._isInAdmins(msg.sender),
            "Access denied: You are not a User or Admin"
        );

        Premium[] storage premiums = userPremiums[user];
        for (uint256 i = 0; i < premiums.length; i++) {
            if (premiums[i].indexUserPolicy == policyIndex) {
                return premiums[i].policyPremium;
            }
        }

        revert("Premium not set for this policy index");
    }

    function payPremium(uint256 policyIndex) public payable {
        require(roleManagement._isInUsers(msg.sender), "Access denied: You are not User");

        uint256[] memory userPolicies = policyManagement.getUserPolicies(msg.sender);
        require(policyIndex <= userPolicies.length, "Invalid policy index");

        // Check premium is set or not
        uint256 policyPremium = getUserPremium(msg.sender, policyIndex);
        require(msg.value == policyPremium, "Incorrect premium amount");

        // Add to the pool
        uint256 policyId = userPolicies[policyIndex - 1];
        premiumsPaid[policyId] += msg.value;
        poolBalance += msg.value;

        emit PremiumPaid(policyId, msg.value);
        emit PoolBalanceUpdated(poolBalance);
    }

    function getPoolBalance() public view returns (uint256) {
        require(
            roleManagement._isInAdmins(msg.sender),
            "Access denied: You are not Admin"
        );
        return poolBalance;
    }

}