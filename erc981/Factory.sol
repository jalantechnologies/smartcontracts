pragma solidity ^0.4.24;

contract Factory {

    /*
     *  Events
     */
    event ContractInstantiation(address sender, address instantiation);

    /*
     *  Storage
     */
    mapping(address => bool) public isInstantiation;
    mapping(address => address[]) public instantiations;
    address factoryOwner;

    constructor () public {
      factoryOwner = msg.sender;
    }

    /*
     * Public functions
     */
    /// @dev Returns number of instantiations by creator.
    /// @return Returns number of instantiations by creator.
    function getInstantiationCount()
        public
        constant
        returns (uint)
    {
        return instantiations[factoryOwner].length;
    }

    function getInstantiations()
        public
        constant
        returns (address[])
    {
        return instantiations[factoryOwner];
    }

    /*
     * Internal functions
     */
    /// @dev Registers contract in factory registry.
    /// @param instantiation Address of contract instantiation.
    function register(address instantiation)
        internal
    {
        isInstantiation[instantiation] = true;
        instantiations[factoryOwner].push(instantiation);
        emit ContractInstantiation(factoryOwner, instantiation);
    }
}