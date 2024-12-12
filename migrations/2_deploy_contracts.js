const RoleManagement = artifacts.require("RoleManagement");
const PolicyManagement = artifacts.require("PolicyManagement");
const PremiumCollection = artifacts.require("PremiumCollection");

module.exports = async function (deployer, network, accounts) {
  // Step 1: Deploy RoleManagement contract
  const initialAdmins = [accounts[0], accounts[1]]; // Replace with your desired admin addresses
  await deployer.deploy(RoleManagement, initialAdmins);
  const roleManagementInstance = await RoleManagement.deployed();

  console.log("✅ RoleManagement deployed at:", roleManagementInstance.address);

  // Step 2: Deploy PolicyManagement contract with RoleManagement address
  await deployer.deploy(PolicyManagement, roleManagementInstance.address);
  const policyManagementInstance = await PolicyManagement.deployed();

  console.log("✅ PolicyManagement deployed at:", policyManagementInstance.address);

  // Step 3: Deploy PremiumCollection contract with RoleManagement and PolicyManagement addresses
  await deployer.deploy(PremiumCollection, roleManagementInstance.address, policyManagementInstance.address);
  const premiumCollectionInstance = await PremiumCollection.deployed();

  console.log("✅ PremiumCollection deployed at:", premiumCollectionInstance.address);
};