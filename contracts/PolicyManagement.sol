// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    mapping(uint256 => Policy) policies;

    uint256 policyCount;                  

    event PolicyCreated(
        uint256 policyID,
        string insurancePlan,
        string basePremiumRate,
        uint256 deductible,
        uint256 insuranceCoverage,
        uint256 thirdPartyLiability,
        string[] cover
    );

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

        emit PolicyCreated(policyCount, _insurancePlan, _basePremiumRate, _deductible, _insuranceCoverage, _thirdPartyLiability, _cover);
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
        require(_policyID <= policyCount, "Policy does not exist");

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

    function isPolicyActive(uint256 policyID) public view returns (uint256 _policyID, string memory) {
    // ตรวจสอบว่า policyID มีอยู่ใน mapping หรือไม่
    if (policyID > 0 && policyID <= policyCount) {
        return (_policyID, "Active"); // หาก policyID อยู่ใน mapping
    } else {
        return (_policyID, "Not Active"); // หาก policyID ไม่อยู่ใน mapping
    }
}
}