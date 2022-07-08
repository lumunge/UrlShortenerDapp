var UrlShortener = artifacts.require("./UrlShortener.sol");

module.exports = function (deployer) {
  deployer.deploy(UrlShortener);
};
