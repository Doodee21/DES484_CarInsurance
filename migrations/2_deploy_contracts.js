const RoleManagement = artifacts.require("RoleManagement");
const PolicyManagement = artifacts.require("PolicyManagement");
const CarInsuranceClaimSystem = artifacts.require("CarInsuranceClaimSystem");

module.exports = async function (deployer) {
  // Deploy RoleManagement with an array containing the single address
  await deployer.deploy(RoleManagement, ["0x6571C20AF21D33cbcfE5d9d24f175636069bBA74"]);  // Pass the address in an array
  await deployer.deploy(PolicyManagement, ["0x6571C20AF21D33cbcfE5d9d24f175636069bBA74"]);

  // Get the deployed contract addresses
  const roleManagementAddress = RoleManagement.address;
  const policyManagementAddress = PolicyManagement.address;

  // Deploy CarInsuranceClaimSystem with RoleManagement and PolicyManagement addresses
  await deployer.deploy(CarInsuranceClaimSystem, roleManagementAddress, policyManagementAddress);
};
