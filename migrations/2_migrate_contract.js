const Roles = artifacts.require("Roles");

module.exports = function(deployer) {
    deployer.deploy(Roles);
};
