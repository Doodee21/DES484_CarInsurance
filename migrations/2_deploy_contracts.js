const RoleManagement = artifacts.require("RoleManagement");
const PolicyManagement = artifacts.require("PolicyManagement");
const PremiumCollection = artifacts.require("PremiumCollection");
const CarInsuranceClaimSystem = artifacts.require("CarInsuranceClaimSystem");
const CarInsurancePayoutSystem = artifacts.require("CarInsurancePayoutSystem");

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

  // Step 4: Deploy CarInsurancePayoutSystem BEFORE CarInsuranceClaimSystem
  // Pass RoleManagement and PolicyManagement addresses to CarInsurancePayoutSystem
  await deployer.deploy(CarInsurancePayoutSystem, premiumCollectionInstance.address, roleManagementInstance.address, policyManagementInstance.address);
  const carInsurancePayoutSystemInstance = await CarInsurancePayoutSystem.deployed();

  console.log("✅ CarInsurancePayoutSystem deployed at:", carInsurancePayoutSystemInstance.address);

  // Step 5: Deploy CarInsuranceClaimSystem AFTER CarInsurancePayoutSystem
  // Pass RoleManagement, PolicyManagement, and CarInsurancePayoutSystem addresses to CarInsuranceClaimSystem
  await deployer.deploy(CarInsuranceClaimSystem, roleManagementInstance.address, policyManagementInstance.address, carInsurancePayoutSystemInstance.address);
  const carInsuranceClaimSystemInstance = await CarInsuranceClaimSystem.deployed();

  console.log("✅ CarInsuranceClaimSystem deployed at:", carInsuranceClaimSystemInstance.address);
};
