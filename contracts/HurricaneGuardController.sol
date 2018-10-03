/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description Controller contract
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock
 *
 * HurricaneGuard with Underwriting and Payout
 * Modified work
 *
 * @copyright (c) 2018 Joel Martínez
 * @author Joel Martínez
 */


pragma solidity 0.4.24;


import "./Ownable.sol";
import "./HurricaneGuardControlledContract.sol";
import "./HurricaneGuardConstants.sol";


contract HurricaneGuardController is Ownable, HurricaneGuardConstants {
  struct Controller {
    address addr;
    bool isControlled;
    bool isInitialized;
  }

  mapping (bytes32 => Controller) public contracts;
  bytes32[] public contractIds;

  /**
  * Constructor.
  */
  constructor() public {
    registerContract(owner, "HG.Owner", false);
    registerContract(address(this), "HG.Controller", false);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    owner = _newOwner;
    setContract(_newOwner, "HG.Owner", false);
  }

  /**
  * Get contract address from ID. This function is called by the
  * contract's setContracts function.
  * @param _id         ID of contract
  * @return The address of the contract.
  */
  function getContract(bytes32 _id) public returns (address _addr) {
    _addr = contracts[_id].addr;
  }

  /**
  * Registration of contracts.
  * It will only accept calls of deployments initiated by the owner.
  * @param _id         ID of contract
  * @return  bool        success
  */
  function registerContract(address _addr, bytes32 _id, bool _isControlled) public onlyOwner returns (bool _result) {
    setContract(_addr, _id, _isControlled);
    contractIds.push(_id);
    _result = true;
  }

  /**
  * Deregister a contract.
  * In future, contracts should be exchangeable.
  * @param _id         ID of contract
  * @return  bool        success
  */
  function deregister(bytes32 _id) public onlyOwner returns (bool _result) {
    if (getContract(_id) == 0x0) {
      return false;
    }
    setContract(0x0, _id, false);
    _result = true;
  }

  /**
  * After deploying all contracts, this function is called and calls
  * setContracts() for every registered contract.
  * This call pulls the addresses of the needed contracts in the respective contract.
  * We assume that contractIds.length is small, so this won't run out of gas.
  */
  function setAllContracts() public onlyOwner {
    HurricaneGuardControlledContract controlledContract;
    // TODO: Check for upper bound for i
    // i = 0 is FD.Owner, we skip this. // check!
    for (uint i = 0; i < contractIds.length; i++) {
      if (contracts[contractIds[i]].isControlled == true) {
        controlledContract = HurricaneGuardControlledContract(contracts[contractIds[i]].addr);
        controlledContract.setContracts();
      }
    }
  }

  function setOneContract(uint i) public onlyOwner {
    HurricaneGuardControlledContract controlledContract;
    // TODO: Check for upper bound for i
    controlledContract = HurricaneGuardControlledContract(contracts[contractIds[i]].addr);
    controlledContract.setContracts();
  }

  /**
  * Destruct one contract.
  * @param _id         ID of contract to destroy.
  */
  function destructOne(bytes32 _id) public onlyOwner {
    address addr = getContract(_id);
    if (addr != 0x0) {
      HurricaneGuardControlledContract(addr).destruct();
    }
  }

  /**
  * Destruct all contracts.
  * We assume that contractIds.length is small, so this won't run out of gas.
  * Otherwise, you can still destroy one contract after the other with destructOne.
  */
  function destructAll() public onlyOwner {
    // TODO: Check for upper bound for i
    for (uint i = 0; i < contractIds.length; i++) {
      if (contracts[contractIds[i]].isControlled == true) {
        destructOne(contractIds[i]);
      }
    }

    selfdestruct(owner);
  }

  /**
  * Store address of one contract in mapping.
  * @param _addr       Address of contract
  * @param _id         ID of contract
  */
  function setContract(address _addr, bytes32 _id, bool _isControlled) internal {
    contracts[_id].addr = _addr;
    contracts[_id].isControlled = _isControlled;
  }
}
