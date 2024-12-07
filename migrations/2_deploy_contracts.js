const RoleManagement = artifacts.require("RoleManagement");
const PolicyManagement = artifacts.require("PolicyManagement");
const CarInsuranceClaimSystem = artifacts.require("CarInsuranceClaimSystem");

module.exports = async function (deployer) {
  // Deploy RoleManagement and PolicyManagement first
  await deployer.deploy(RoleManagement);
  await deployer.deploy(PolicyManagement);

  // Get the deployed contract addresses
  const roleManagementAddress = RoleManagement.address;
  const policyManagementAddress = PolicyManagement.address;

  // Deploy CarInsuranceClaimSystem with RoleManagement and PolicyManagement addresses
  await deployer.deploy(CarInsuranceClaimSystem, roleManagementAddress, policyManagementAddress);
};
