// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./RoleManagement.sol";
import "./PolicyManagement.sol";

contract CarInsuranceClaimSystem {

    RoleManagement roleManagement;
    PolicyManagement policyManagement;

    enum ClaimStatus { Pending, Approved, Rejected } // สถานะคำร้อง

    struct Claim {
        uint id; // หมายเลขคำร้อง
        address claimant; // ผู้เสียหายที่ส่งคำร้อง
        string name; // ชื่อของผู้ยื่นคำร้อง
        string policy; // ประเภทกรมธรรม์
        string incidentDate; // วันที่เกิดเหตุ
        string details; // รายละเอียดเพิ่มเติม
        ClaimStatus status; // Pending, Approved, Rejected
        string[] cover; // ประเภทความเสียหาย (เช่น "Own Damage", "Theft", etc.)
        string[] ipfsHashes; // Array ของ IPFS Hash หลักฐาน
        uint timestamp; // เวลาที่ส่งคำร้อง
    }

    mapping(uint => Claim) public claims; // เก็บคำร้อง
    uint public claimCount; // จำนวนคำร้องทั้งหมด
    mapping(string => bool) public uploadedHashes; // เก็บ Hash ที่เคยอัปโหลดแล้ว

    event ClaimSubmitted(uint claimId, address indexed claimant, string name, string policy);
    event ClaimRejected(uint claimId); // Event เมื่อคำร้องถูกปฏิเสธ
    event ClaimApproved(uint claimId); // Event เมื่อคำร้องได้รับอนุมัติ


    constructor(address _roleManagementAddress, address _policyManagementAddress) {
        roleManagement = RoleManagement(_roleManagementAddress);
        policyManagement = PolicyManagement(_policyManagementAddress);
    }

    /// @notice ผู้เสียหายส่งคำร้องพร้อมแนบหลาย IPFS Hash
    function submitClaim(
        string memory _name,
        string memory _policy,
        string memory _incidentDate,
        string memory _details,
        string[] memory _cover,
        string[] memory _ipfsHashes
    ) public {
        require(
            roleManagement._isInUsers(msg.sender),
            "Access denied: You are not Users"
        );
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_policy).length > 0, "Policy cannot be empty");
        require(_cover.length > 0, "Cover cannot be empty");
        require(_ipfsHashes.length > 0, "No IPFS hashes provided");

        // ตรวจสอบว่าแต่ละ Hash ซ้ำหรือไม่
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
                    status: ClaimStatus.Rejected, // ปฏิเสธอัตโนมัติ
                    cover: _cover,
                    ipfsHashes: _ipfsHashes,
                    timestamp: block.timestamp
                });

                emit ClaimRejected(claimCount);
                return;
            }
        }

        // เพิ่มค่า claimCount ก่อนบันทึกคำร้อง
        claimCount++;
        ClaimStatus initialStatus = ClaimStatus.Pending; // สถานะเริ่มต้น

        // ตรวจสอบว่า "Own Damage" อยู่ใน Cover เพื่ออนุมัติอัตโนมัติ
        for (uint i = 0; i < _cover.length; i++) {
            if (keccak256(abi.encodePacked(_cover[i])) == keccak256(abi.encodePacked("Own Damage"))) {
                initialStatus = ClaimStatus.Approved; // เปลี่ยนสถานะเป็น Approved
                emit ClaimApproved(claimCount); // ส่ง Event ว่าได้รับอนุมัติ
                break;
            }
        }

        // บันทึกคำร้องใหม่
        claims[claimCount] = Claim({
            id: claimCount,
            claimant: msg.sender,
            name: _name,
            policy: _policy,
            incidentDate: _incidentDate,
            details: _details,
            status: initialStatus, // ใช้สถานะจาก initialStatus
            cover: _cover,
            ipfsHashes: _ipfsHashes,
            timestamp: block.timestamp
        });

        // บันทึก Hash ทุกตัวลงระบบ
        for (uint i = 0; i < _ipfsHashes.length; i++) {
            uploadedHashes[_ipfsHashes[i]] = true;
        }

        emit ClaimSubmitted(claimCount, msg.sender, _name, _policy);
    }

    /// @notice ฟังก์ชันให้แอดมินตรวจสอบคำร้อง
    function reviewClaim(
        uint _claimId,
        bool _approvedStatus
    ) public  {
        require(
            roleManagement._isInAdmins(msg.sender),
            "Access denied: You are not Admin"
        );
        Claim storage claim = claims[_claimId];
        require(claim.status == ClaimStatus.Pending, "Claim is not in pending state");

        if (_approvedStatus) {
            claim.status = ClaimStatus.Approved;
            emit ClaimApproved(_claimId);
        } else {
            claim.status = ClaimStatus.Rejected;
            emit ClaimRejected(_claimId);
        }
    }

    /// @notice View claim status
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