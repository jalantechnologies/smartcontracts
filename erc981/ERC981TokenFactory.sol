pragma solidity ^0.4.24;
import "./Factory.sol";
import "./ERC981Token.sol";

contract ERC981TokenFactory is Factory {

    /*
     * Public functions
     */
    /// @param _owner Owner
    /// @return Returns Token contract address
    function create(address _owner, uint256 _amount, string _tokenType, string _metadata, string _tokenName, string _tokenSymbol)
        public
        returns (address contractAddress)
    {
        contractAddress = new ERC981Token(_owner, _amount, _tokenType, _metadata, _tokenName, _tokenSymbol);
        register(contractAddress);
    }
}