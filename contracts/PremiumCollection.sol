// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./PolicyManagement.sol";
import "./RoleManagement.sol";

contract PremiumCollection {
    RoleManagement private roleManagement;
    PolicyManagement private policyManagement;

    struct Premium {
        uint256 policyID; 
        uint256 policyPremium;
        uint256 amountPaid;
    }

    mapping(address => Premium[]) private userPremiums;
    uint256 private poolBalance;

    event PremiumPaid(address indexed user, uint256 policyId, uint256 amount);
    event PoolBalanceUpdated(uint256 newBalance);
    event UserPremiumSet(address indexed user, uint256 policyID, uint256 premium);
    event AmountPaidReset(address indexed user, uint256 policyID);

    constructor(address _roleManagementAddress, address _policyManagementAddress) {
        roleManagement = RoleManagement(_roleManagementAddress);
        policyManagement = PolicyManagement(_policyManagementAddress);
    }

    function setUserPremium(address user, uint256 policyID, uint256 policyPremium) public {
        require(
            roleManagement._isInAdmins(msg.sender),
            "Access denied: You are not Admin"
        );
        require(roleManagement._isInUsers(user), "Invalid user address");
        require(policyPremium > 0, "Premium must be greater than zero");

        uint256[] memory userPolicies = policyManagement.getUserPolicies(user);
        bool hasPolicy = false;
        for (uint256 i = 0; i < userPolicies.length; i++) {
            if (userPolicies[i] == policyID) {
                hasPolicy = true;
                break;
            }
        }
        require(hasPolicy, "User does not have this policy");

        Premium[] storage premiums = userPremiums[user];
        for (uint256 i = 0; i < premiums.length; i++) {
            require(
                premiums[i].policyID != policyID,
                "Premium already set for this policy"
            );
        }

        premiums.push(Premium({
            policyID: policyID,
            policyPremium: policyPremium,
            amountPaid: 0
        }));

        emit UserPremiumSet(user, policyID, policyPremium);
    }

    function paidPremium(address user, uint256 policyID) public view returns (bool) {
    require(
        roleManagement._isInUsers(msg.sender) || roleManagement._isInAdmins(msg.sender),
        "Access denied: You are not a User or Admin"
    );

    Premium[] storage premiums = userPremiums[user];
    for (uint256 i = 0; i < premiums.length; i++) {
        if (premiums[i].policyID == policyID) {
            return premiums[i].amountPaid > 0;
        }
    }

    revert("Premium not found for this policy ID");
}

    function payPremium(uint256 policyID) public payable {
        require(
            roleManagement._isInUsers(msg.sender), 
            "Access denied: You are not User"
        );

        uint256[] memory userPolicies = policyManagement.getUserPolicies(msg.sender);
        bool hasPolicy = false;
        for (uint256 i = 0; i < userPolicies.length; i++) {
            if (userPolicies[i] == policyID) {
                hasPolicy = true;
                break;
            }
        }
        require(hasPolicy, "You do not own this policy");

        Premium[] storage premiums = userPremiums[msg.sender];
        bool paymentMade = false;
        
        for (uint256 i = 0; i < premiums.length; i++) {
            if (premiums[i].policyID == policyID) {
                require(premiums[i].amountPaid < premiums[i].policyPremium, "Premium already fully paid");
                require(msg.value + premiums[i].amountPaid <= premiums[i].policyPremium, "Exceeds premium amount");

                premiums[i].amountPaid += msg.value;

                poolBalance += msg.value;

                emit PremiumPaid(msg.sender, policyID, msg.value);
                emit PoolBalanceUpdated(poolBalance);
                paymentMade = true;
                break;
            }
        }

        require(paymentMade, "Payment failed or premium not set");
    }

    function getPoolBalance() public view returns (uint256) {
        require(
            roleManagement._isInAdmins(msg.sender),
            "Access denied: You are not Admin"
        );
        return poolBalance;
    }

    function resetAmountPaid(address user, uint256 policyID) public {
        require(
            roleManagement._isInAdmins(msg.sender), 
            "Access denied: You are not Admin"
        );

        Premium[] storage premiums = userPremiums[user];
        bool resetDone = false;

        for (uint256 i = 0; i < premiums.length; i++) {
            if (premiums[i].policyID == policyID) {
                premiums[i].amountPaid = 0;
                resetDone = true;

                emit AmountPaidReset(user, policyID);
                break;
            }
        }

        require(resetDone, "Policy not found or premium not set");
    }
}