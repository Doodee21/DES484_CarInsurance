const CarInsuranceClaimProcessing = artifacts.require("CarInsuranceClaimProcessing");
const CarInsurancePayoutDistribution = artifacts.require("CarInsurancePayoutDistribution");

module.exports = async function (deployer) {
    await deployer.deploy(CarInsuranceClaimProcessing);
    const claimProcessingInstance = await CarInsuranceClaimProcessing.deployed();
    
    await deployer.deploy(CarInsurancePayoutDistribution, claimProcessingInstance.address);
};
