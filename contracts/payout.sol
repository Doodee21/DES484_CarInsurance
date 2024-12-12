// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./PremiumCollection.sol";
import "./claims.sol";
import "./RoleManagement.sol";

contract CarInsurancePayoutSystem {

    PremiumCollection private premiumCollection;
    CarInsuranceClaimSystem private carInsuranceClaimSystem;

    event PayoutIssued(uint claimId, address indexed claimant, uint256 amount);

    constructor(address _premiumCollectionAddress, address _carInsuranceClaimSystemAddress) {
        premiumCollection = PremiumCollection(_premiumCollectionAddress);
        carInsuranceClaimSystem = CarInsuranceClaimSystem(_carInsuranceClaimSystemAddress);
    }

    function triggerPayout(uint _claimId, address claimant) external {
        require(msg.sender == address(carInsuranceClaimSystem), "Access denied: Unauthorized source");

        _payoutToUser(claimant, _claimId);
    }

    function _payoutToUser(address user, uint _claimId) internal {
        uint256 poolBalance = premiumCollection.getPoolBalance();
        require(poolBalance > 0, "Insufficient pool balance");

        uint256 payoutAmount = calculatePayout(user);
        require(payoutAmount > 0, "Payout amount must be greater than zero");

        premiumCollection.payOut(user, payoutAmount);
        emit PayoutIssued(_claimId, user, payoutAmount);
    }

    function calculatePayout(address user) public view returns (uint256) {
        uint256 coverageLimit = premiumCollection.policyManagement().getUserCoverageLimit(user);
        
        uint256 minRange = coverageLimit / 10; // 10%
        uint256 maxRange = coverageLimit / 2;  // 50%

        uint256 payoutAmount = (maxRange + minRange) / 2; // Example logic to calculate payout as the midpoint of the range
        return payoutAmount;
    }
}
