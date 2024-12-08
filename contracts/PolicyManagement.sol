// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./RoleManagement.sol";

contract PolicyManagement {

    RoleManagement private roleManagement;

    struct Policy {
        uint256 policyID;          
        string insurancePlan;            
        string basePremiumRate;
        uint256 deductible;
        uint256 insuranceCoverage;
        uint256 thirdPartyLiability;
        string[] cover;         
    }

    mapping(uint256 => Policy) public policies;
    mapping(address => uint256[]) internal userPolicies;

    uint256 public policyCount;               

    event PolicyCreated(
        uint256 policyID,
        address indexed user,
        string insurancePlan,
        string basePremiumRate,
        uint256 deductible,
        uint256 insuranceCoverage,
        uint256 thirdPartyLiability,
        string[] cover
    );

    event PolicySelected(address indexed user, uint256 policyID);

    constructor(address _roleManagementAddress) {
        roleManagement = RoleManagement(_roleManagementAddress);
        policyCount = 0;
    }

    function createPolicy(
        string memory _insurancePlan,
        string memory _basePremiumRate,
        uint256 _deductible,
        uint256 _insuranceCoverage,
        uint256 _thirdPartyLiability,
        string[] memory _cover
    ) public returns (uint256) {
        require(
            roleManagement._isInAdmins(msg.sender),
            "Access denied: You are not Admin"
        );
        policyCount++;
        policies[policyCount] = Policy(policyCount, _insurancePlan, _basePremiumRate, _deductible, _insuranceCoverage, _thirdPartyLiability, _cover);

        emit PolicyCreated(policyCount, msg.sender, _insurancePlan, _basePremiumRate, _deductible, _insuranceCoverage, _thirdPartyLiability, _cover);
        return policyCount;
    }

    function viewPolicy(uint256 _policyID) public view returns (
        uint256 policyID,
        string memory insurancePlan,
        string memory basePremiumRate,
        uint256 deductible,
        uint256 insuranceCoverage,
        uint256 thirdPartyLiability,
        string[] memory cover
    ) {
        require(
            roleManagement._isInAdmins(msg.sender),
            "Access denied: You are not Admin"
        );
        require(_policyID <= policyCount && _policyID > 0, "Policy does not exist");

        Policy storage policy = policies[_policyID];

        return (
            policy.policyID,
            policy.insurancePlan,
            policy.basePremiumRate,
            policy.deductible,
            policy.insuranceCoverage,
            policy.thirdPartyLiability,
            policy.cover
        );
    }

    function isPolicyActive(uint256 policyID) public view returns (uint256 policy_ID, string memory) {
        require(
            roleManagement._isInAdmins(msg.sender),
            "Access denied: You are not Admin"
        );

        if (policyID > 0 && policyID <= policyCount) {
            return (policyID, "Active");
        } else {
            return (policyID, "Not Active");
        }
    }

    function selectPolicy(uint256 _policyID) public {
    require(
        roleManagement._isInUsers(msg.sender),
        "Access denied: You are not a User"
    );
    require(
        _policyID > 0 && _policyID <= policyCount,
        "Policy does not exist"
    );

    userPolicies[msg.sender].push(_policyID);

    emit PolicySelected(msg.sender, _policyID);
}

    function viewSelectedPolicy(address user, uint256 index) public view returns (
    uint256 policyID,
    string memory insurancePlan,
    string memory basePremiumRate,
    uint256 deductible,
    uint256 insuranceCoverage,
    uint256 thirdPartyLiability,
    string[] memory cover
) {
    require(
        roleManagement._isInUsers(msg.sender) || roleManagement._isInAdmins(msg.sender),
        "Access denied: You are not a User or Admin"
    );

    // Check user has a Policy or not
    require(userPolicies[user].length > 0, "User has not selected any policy");

    require(index < userPolicies[user].length, "Invalid policy index");

    uint256 selectedPolicyID = userPolicies[user][index];
    Policy storage policy = policies[selectedPolicyID];

    return (
        policy.policyID,
        policy.insurancePlan,
        policy.basePremiumRate,
        policy.deductible,
        policy.insuranceCoverage,
        policy.thirdPartyLiability,
        policy.cover
    );
}

function getUserPolicies(address user) public view returns (uint256[] memory) {
    return userPolicies[user];
}
}