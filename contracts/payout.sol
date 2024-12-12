// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./PremiumCollection.sol";
import "./claims.sol";
import "./RoleManagement.sol";

contract CarInsurancePayoutSystem {

    PremiumCollection private premiumCollection;
    CarInsuranceClaimSystem private carInsuranceClaimSystem;
    RoleManagement private roleManagement;

    event PayoutIssued(uint claimId, address indexed claimant, uint256 amount);

    constructor(address _premiumCollectionAddress, address _carInsuranceClaimSystemAddress, address _roleManagementAddress) {
        premiumCollection = PremiumCollection(_premiumCollectionAddress);
        carInsuranceClaimSystem = CarInsuranceClaimSystem(_carInsuranceClaimSystemAddress);
        roleManagement = RoleManagement(_roleManagementAddress);
    }

    modifier onlyAdmin() {
        require(roleManagement.hasRole(roleManagement.ADMIN_ROLE(), msg.sender), "Access denied: You are not an Admin");
        _;
    }

    function triggerPayout(uint _claimId, address claimant) external {
        require(
            roleManagement.hasRole(roleManagement.ADMIN_ROLE(), msg.sender) || msg.sender == address(carInsuranceClaimSystem), 
            "Access denied: Unauthorized source"
        );
        _payoutToUser(claimant, _claimId);
    }

    function _payoutToUser(address user, uint _claimId) internal {
        uint256 poolBalance = premiumCollection.getPoolBalance();
        require(poolBalance > 0, "Insufficient pool balance");

        uint256 payoutAmount = calculatePayout(user, _claimId);
        require(payoutAmount > 0, "Payout amount must be greater than zero");

        require(poolBalance >= payoutAmount, "Insufficient funds in the pool for payout");
        
        (bool success, ) = payable(user).call{value: payoutAmount}("");
        require(success, "Payout transfer failed");

        premiumCollection.decreasePoolBalance(payoutAmount);
        
        emit PayoutIssued(_claimId, user, payoutAmount);
    }

    function calculatePayout(address user, uint _claimId) public view returns (uint256) {
        // Call to premiumCollection to get the coverage limit of the user
        uint256 coverageLimit = premiumCollection.getUserCoverageLimit(user);
        require(coverageLimit > 0, "Coverage limit must be greater than zero");
        
        // Extract claim details from CarInsuranceClaimSystem
        (
            , // Skip claimant
            , // Skip name
            , // Skip policy
            , // Skip incidentDate
            , // Skip details
            , // Skip claim status
            , // Skip cover
            , // Skip ipfsHashes
            uint256 claimAmount // Extract the claim amount (assuming it's returned as part of the data)
        ) = carInsuranceClaimSystem.viewClaimStatus(_claimId);
        
        // Calculate the pre-approved payout range
        uint256 minRange = coverageLimit / 10; // 10% of coverage limit
        uint256 maxRange = coverageLimit / 2;  // 50% of coverage limit

        // Check if the claim amount is within the range
        require(claimAmount >= minRange && claimAmount <= maxRange, "Claim amount is outside the pre-approved range");
        
        // Calculate the payout amount
        uint256 payoutAmount = claimAmount > coverageLimit ? coverageLimit : claimAmount; // Pay lesser of claim amount or coverage limit
        return payoutAmount;
    }
}
