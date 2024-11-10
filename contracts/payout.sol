// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./claims.sol";

contract CarInsurancePayoutDistribution {
    CarInsuranceClaimProcessing claimProcessing;

    constructor(address _claimProcessingAddress) {
        claimProcessing = CarInsuranceClaimProcessing(_claimProcessingAddress);
    }

    function distributePayout(uint _claimId, address payable _claimant) public {
        (bool processed, bool approved, , uint damageAmount) = claimProcessing.viewClaimStatus(_claimId);

        require(processed, "Claim not processed");
        require(approved, "Claim not approved");

        uint payoutAmount = calculatePayout(damageAmount);
        _claimant.transfer(payoutAmount);
    }

    function calculatePayout(uint damageAmount) internal pure returns (uint) {
        return damageAmount; // Use the damage amount as the payout
    }

    function checkPayoutStatus(uint /* _claimId */) public pure returns (bool) {
        // Placeholder logic for checking payout status
        return true; // You might implement a proper logic later
    }

    function getTotalPayouts() public view returns (uint) {
        return address(this).balance; // Placeholder for total payouts
    }
}