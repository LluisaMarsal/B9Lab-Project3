var ConvertLib = artifacts.require('./ConvertLib.sol')
var RockPaperScissors = artifacts.require('./RockPaperScissors.sol')

module.exports = function (deployer) {
  deployer.deploy(ConvertLib)
  deployer.link(ConvertLib, RockPaperScissors)
  deployer.deploy(RockPaperScissors)
}
