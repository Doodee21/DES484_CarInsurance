// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FraudDetection is AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;

    // Define roles for access control
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ANALYST_ROLE = keccak256("ANALYST_ROLE");

    Counters.Counter private claimIdCounter;

    enum ClaimStatus { Pending, Approved, Rejected, Blacklisted }

    struct Claim {
        uint256 id;
        address claimant;
        uint256 createdAt;
        string claimantHistory;
        string documents;
        ClaimStatus status;
        uint256 claimAmount;
    }

    mapping(uint256 => Claim) public claims;
    mapping(address => bool) public blacklistedClaimants;
    mapping(address => uint256) public claimantClaimCount; 

   
    event ClaimSubmitted(uint256 claimId, address claimant);
    event ClaimStatusUpdated(uint256 claimId, ClaimStatus status);
    event BlacklistedClaimant(address indexed claimant);
    event ClaimAmountUpdated(uint256 claimId, uint256 amount);

    AggregatorV3Interface internal priceFeed;

    constructor(address _priceFeedAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    
    function collectClaimData(
        string memory _claimantHistory,
        string memory _documents,
        uint256 _claimAmount
    ) external {
        require(_claimAmount > 0, "Claim amount must be greater than zero.");

        claimIdCounter.increment();
        uint256 newClaimId = claimIdCounter.current();

        claims[newClaimId] = Claim({
            id: newClaimId,
            claimant: msg.sender,
            claimantHistory: _claimantHistory,
            documents: _documents,
            status: ClaimStatus.Pending,
            createdAt: block.timestamp,
            claimAmount: _claimAmount
        });

        claimantClaimCount[msg.sender] += 1;

        emit ClaimSubmitted(newClaimId, msg.sender);
    }

    function analyzeClaimHistory(address _claimant) internal view returns (bool) {
        
        if (claimantClaimCount[_claimant] > 3) {
            return true; 
        }

        
        (, int price, , , ) = priceFeed.latestRoundData();
        if (price < 0) {
            return true; 
        }

        return false;
    }

    
    function patternRecognition(uint256 _claimId) external onlyRole(ANALYST_ROLE) {
        Claim storage claim = claims[_claimId];
        require(claim.status == ClaimStatus.Pending, "Claim must be pending");

        bool isFraudulent = analyzeClaimHistory(claim.claimant);

        if (isFraudulent) {
            claim.status = ClaimStatus.Blacklisted;
            blacklistedClaimants[claim.claimant] = true;
            emit ClaimStatusUpdated(_claimId, ClaimStatus.Blacklisted);
            emit BlacklistedClaimant(claim.claimant);
        }
    }

    
    function validateClaimData(uint256 _claimId, bool _isValid) external onlyRole(ANALYST_ROLE) {
        Claim storage claim = claims[_claimId];
        require(claim.status == ClaimStatus.Pending, "Claim must be pending");

        if (_isValid) {
            claim.status = ClaimStatus.Approved;
        } else {
            claim.status = ClaimStatus.Rejected;
            blacklistedClaimants[claim.claimant] = true;
            emit BlacklistedClaimant(claim.claimant);
        }
        emit ClaimStatusUpdated(_claimId, claim.status);
    }

    function updateClaimAmount(uint256 _claimId, uint256 _newAmount) external onlyRole(ANALYST_ROLE) {
        Claim storage claim = claims[_claimId];
        require(claim.status == ClaimStatus.Pending, "Claim must be pending");
        claim.claimAmount = _newAmount;
        emit ClaimAmountUpdated(_claimId, _newAmount);
    }

    function auditClaim(uint256 _claimId) external view returns (Claim memory) {
        return claims[_claimId];
    }

    
    function blacklistPolicyholder(address _claimant) external onlyRole(ADMIN_ROLE) {
        blacklistedClaimants[_claimant] = true;
        emit BlacklistedClaimant(_claimant);
    }

   
    function isBlacklisted(address _claimant) external view returns (bool) {
        return blacklistedClaimants[_claimant];
    }
}
