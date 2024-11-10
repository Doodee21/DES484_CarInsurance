// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CarInsuranceClaimProcessing {
    struct Claim {
        uint id;
        address policyholder;
        string accidentDetails; 
        bool processed; // True if claim is evaluated
        bool approved;  // True if claim is approved
        string rejectionReason; // Reason for rejection, if any
        uint damageAmount; 
    }
    
    mapping(uint => Claim) public claims;
    uint public claimCount;

    event ClaimSubmitted(uint claimId, address indexed policyholder);
    event ClaimEvaluated(uint claimId, bool approved, string rejectionReason);
    
    // Constructor to initialize claimCount
    constructor() {
        claimCount = 0; //  start claimCount at 0
    }

    function submitClaim(string memory _accidentDetails, uint _damageAmount) public {
        claimCount++;
        claims[claimCount] = Claim(claimCount, msg.sender, _accidentDetails, false, false, "", _damageAmount);
        emit ClaimSubmitted(claimCount, msg.sender);
    }

    function evaluateClaim(uint _claimId) public {
        bool approved = true; // Assume it is approved for the example
        claims[_claimId].processed = true;
        claims[_claimId].approved = approved;
        if (!approved) {
            claims[_claimId].rejectionReason = "Insufficient evidence"; // Example reason
        }
        emit ClaimEvaluated(_claimId, approved, claims[_claimId].rejectionReason);
    }

    function approveClaim(uint _claimId) public {
        require(claims[_claimId].processed, "Claim not processed");
        claims[_claimId].approved = true;
    }

    function rejectClaim(uint _claimId, string memory _reason) public {
        require(claims[_claimId].processed, "Claim not processed");
        claims[_claimId].approved = false;
        claims[_claimId].rejectionReason = _reason;
    }

    // New getter functions for specific fields
    function isClaimProcessed(uint _claimId) public view returns (bool) {
        return claims[_claimId].processed;
    }

    function isClaimApproved(uint _claimId) public view returns (bool) {
        return claims[_claimId].approved;
    }

    function getClaimRejectionReason(uint _claimId) public view returns (string memory) {
        return claims[_claimId].rejectionReason;
    }

    function getClaimDamageAmount(uint _claimId) public view returns (uint) {
        return claims[_claimId].damageAmount;
    }

    function viewClaimStatus(uint _claimId) public view returns (bool processed, bool approved, string memory reason, uint damageAmount) {
        Claim memory claim = claims[_claimId];
        return (claim.processed, claim.approved, claim.rejectionReason, claim.damageAmount);
    }
}
