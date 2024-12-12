// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./payout.sol";
import "./RoleManagement.sol";
import "./PolicyManagement.sol";

contract CarInsuranceClaimSystem {

    RoleManagement roleManagement;
    PolicyManagement policyManagement;
    CarInsurancePayoutSystem carInsurancePayoutSystem;

    enum ClaimStatus { Pending, Approved, Rejected }

    struct Claim {
        uint id;
        address claimant;
        string name;
        string policy;
        string incidentDate;
        string details;
        ClaimStatus status;
        string[] cover;
        string[] ipfsHashes;
        uint timestamp;
    }

    mapping(uint => Claim) public claims;
    uint public claimCount;
    mapping(string => bool) public uploadedHashes;

    event ClaimSubmitted(uint claimId, address indexed claimant, string name, string policy);
    event ClaimRejected(uint claimId);
    event ClaimApproved(uint claimId);

    constructor(address _roleManagementAddress, address _policyManagementAddress, address _carInsurancePayoutSystemAddress) {
        roleManagement = RoleManagement(_roleManagementAddress);
        policyManagement = PolicyManagement(_policyManagementAddress);
        carInsurancePayoutSystem =  CarInsurancePayoutSystem(_carInsurancePayoutSystemAddress);
    }

    function submitClaim(
        string memory _name,
        string memory _policy,
        string memory _incidentDate,
        string memory _details,
        string[] memory _cover,
        string[] memory _ipfsHashes
    ) public {
        require(
            roleManagement.hasRole(roleManagement.POLICY_HOLDER_ROLE(), msg.sender),
            "Access denied: You are not a Policy Holder"
        );
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_policy).length > 0, "Policy cannot be empty");
        require(_cover.length > 0, "Cover cannot be empty");
        require(_ipfsHashes.length > 0, "No IPFS hashes provided");

        for (uint i = 0; i < _ipfsHashes.length; i++) {
            if (uploadedHashes[_ipfsHashes[i]]) {
                claimCount++;
                claims[claimCount] = Claim({
                    id: claimCount,
                    claimant: msg.sender,
                    name: _name,
                    policy: _policy,
                    incidentDate: _incidentDate,
                    details: _details,
                    status: ClaimStatus.Rejected,
                    cover: _cover,
                    ipfsHashes: _ipfsHashes,
                    timestamp: block.timestamp
                });

                emit ClaimRejected(claimCount);
                return;
            }
        }

        claimCount++;
        ClaimStatus initialStatus = ClaimStatus.Pending;

        for (uint i = 0; i < _cover.length; i++) {
            if (keccak256(abi.encodePacked(_cover[i])) == keccak256(abi.encodePacked("Own Damage"))) {
                initialStatus = ClaimStatus.Approved;
                emit ClaimApproved(claimCount);
                carInsurancePayoutSystem.triggerPayout(claimCount, msg.sender);
                break;
            }
        }

        claims[claimCount] = Claim({
            id: claimCount,
            claimant: msg.sender,
            name: _name,
            policy: _policy,
            incidentDate: _incidentDate,
            details: _details,
            status: initialStatus,
            cover: _cover,
            ipfsHashes: _ipfsHashes,
            timestamp: block.timestamp
        });

        for (uint i = 0; i < _ipfsHashes.length; i++) {
            uploadedHashes[_ipfsHashes[i]] = true;
        }

        emit ClaimSubmitted(claimCount, msg.sender, _name, _policy);
    }

    function reviewClaim(
        uint _claimId,
        bool _approvedStatus
    ) public  {
        require(
            roleManagement.hasRole(roleManagement.ADMIN_ROLE(), msg.sender),
            "Access denied: You are not Admin"
        );
        Claim storage claim = claims[_claimId];
        require(claim.status == ClaimStatus.Pending, "Claim is not in pending state");

        if (_approvedStatus) {
            claim.status = ClaimStatus.Approved;
            emit ClaimApproved(_claimId);
            carInsurancePayoutSystem.triggerPayout(_claimId, claim.claimant);
        } else {
            claim.status = ClaimStatus.Rejected;
            emit ClaimRejected(_claimId);
        }
    }

    function viewClaimStatus(uint _claimId)
        public
        view
        returns (
            address claimant,
            string memory name,
            string memory policy,
            string memory incidentDate,
            string memory details,
            ClaimStatus status,
            string[] memory cover,
            string[] memory ipfsHashes,
            uint timestamp
        )
    {
        Claim memory claim = claims[_claimId];
        return (
            claim.claimant,
            claim.name,
            claim.policy,
            claim.incidentDate,
            claim.details,
            claim.status,
            claim.cover,
            claim.ipfsHashes,
            claim.timestamp
        );
    }
}
