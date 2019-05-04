pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }
    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }
  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }
  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }
  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}
contract ERC981Token {

    struct Token {
        uint256 tokenId;
        address tokenOwner;
        uint256 tokenAmount;
        string tokenType;
        string tokenMetadata;
    }

    address contractInstanceOwner;
    uint256 tokenId = 1;
    mapping(uint256 => Token) tokensMapById;
    mapping(address => Token[]) tokensMapByOwner;
    address[] uniqueOwners;
    string public tokenName;
    string public tokenSymbol;

    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

    function _createTokenWithTokenId(uint256 idForToken, address owner, uint256 amount, string tokenType, string metadata) public payable returns (uint256 _id) {
        tokensMapById[idForToken] = Token(idForToken, owner, amount, tokenType, metadata);
        if (tokensMapByOwner[owner].length == 0) {
            uniqueOwners.push(owner);
        }
        tokensMapByOwner[owner].push(tokensMapById[idForToken]);
        return idForToken;
    }

    function _createToken(address owner, uint256 amount, string tokenType, string metadata) public payable returns (uint256 _id) {
        uint256 idForToken = tokenId;
        _createTokenWithTokenId(idForToken, owner, amount, tokenType, metadata);
        tokenId = SafeMath.add(tokenId, 1);
        return idForToken;
    }

    function _updateTokenAmount(uint256 _tokenId, uint256 _amount) public payable {
        tokensMapById[_tokenId].tokenAmount = _amount;
        for (uint256 i = 0; i < tokensMapByOwner[tokensMapById[_tokenId].tokenOwner].length; i = SafeMath.add(i, 1)) {
            if (tokensMapByOwner[tokensMapById[_tokenId].tokenOwner][i].tokenId == _tokenId) {
                tokensMapByOwner[tokensMapById[_tokenId].tokenOwner][i].tokenAmount = _amount;
                break;
            }
        }
    }

    function _updateTokenOwner(uint256 _tokenId, address owner) public payable {
        uint256 tokenIndexInMapByOwner;
        bool tokenFound = false;
        uint256 i = 0;
        address currentOwner = tokensMapById[_tokenId].tokenOwner;

        // Find the token index in tokensMapByOwner so we can delete it.
        for (i = 0; i < tokensMapByOwner[currentOwner].length; i = SafeMath.add(i, 1)) {
            if (tokensMapByOwner[currentOwner][i].tokenId == _tokenId) {
                tokenIndexInMapByOwner = i;
                tokenFound = true;
                break;
            }
        }

        if (tokenFound == true) {
            _createTokenWithTokenId(
                tokensMapByOwner[currentOwner][tokenIndexInMapByOwner].tokenId,
                owner,
                tokensMapByOwner[currentOwner][tokenIndexInMapByOwner].tokenAmount,
                tokensMapByOwner[currentOwner][tokenIndexInMapByOwner].tokenType,
                tokensMapByOwner[currentOwner][tokenIndexInMapByOwner].tokenMetadata
            );

            // Remove token from current owner
            uint256 newLength = SafeMath.sub(tokensMapByOwner[currentOwner].length, 1);
            for (i = tokenIndexInMapByOwner; i < newLength; i = SafeMath.add(i, 1)) {
                tokensMapByOwner[currentOwner][i] = tokensMapByOwner[currentOwner][SafeMath.add(i, 1)];
            }
            delete tokensMapByOwner[currentOwner][newLength];
            tokensMapByOwner[currentOwner].length = newLength;
        }
    }
    // We require the contract to be instantied with amount, type and metadata
    // associated with the mother token. This mother token will later be used
    // to divide to other owners
    constructor (address owner, uint256 amount, string tokenType, string metadata, string _tokenName, string _tokenSymbol) public payable {
        contractInstanceOwner = owner;
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        _createToken(owner, amount, tokenType, metadata);
    }

    // Divides token (underlying asset) into multiple tokens with specified amount, type and metadata.
    // if and only if identity of msg.sender == ownerOf(_tokenId). A successful divide MUST fire the
    // Transfer event for each new POT (defined below).
    // Owners are array of owner addresses. sigs are array of signatures which required to divide the token
    // (underlying asset). Signature type can be approval or acknowledgement.
    // This method MUST divide token into multiple child tokens or throw, no other outcomes can be possible.
    function divide(uint256 _tokenId, address[] _owners, uint256[] amounts, string[] tokenTypes, string[] metadata, bytes[] sigs) public payable {
        require(msg.sender == tokensMapById[_tokenId].tokenOwner);
        require(_owners.length == amounts.length);
        require(_owners.length == tokenTypes.length);
        require(_owners.length == metadata.length);

        // Ensure that the total amount that needs to be distributed is
        // less than or equal to amount of tokens in _tokenId
        uint256 totalAmountToBeTransferred = 0;
        uint256 i = 0;
        for(i = 0; i < amounts.length; i = SafeMath.add(i, 1)) {
            totalAmountToBeTransferred = SafeMath.add(totalAmountToBeTransferred, amounts[i]);
        }
        require(totalAmountToBeTransferred <= tokensMapById[_tokenId].tokenAmount);

        // Create child tokens and reduce amount for token in _tokenId;
        _updateTokenAmount(_tokenId, SafeMath.sub(tokensMapById[_tokenId].tokenAmount, totalAmountToBeTransferred));
        for(i = 0; i < _owners.length; i = SafeMath.add(i, 1)) {
            emit Transfer(tokensMapById[_tokenId].tokenOwner, _owners[i], _createToken(_owners[i], amounts[i], tokenTypes[i], metadata[i]));
        }
    }

    // Merges tokens (underlying assets) into single token with metadata - and msg.sender the owner
    // of new token. A successful merge MUST fire the Transfer event for new POT (defined below).
    // This method MUST merge tokens into single token or throw, no other outcomes can be possible.
    function merge(uint256[] _tokenIds, uint256 amount, string tokenType, string metadata, bytes[] sigs) public payable {
        uint256 totalAmountToBeTransferred = 0;
        uint256 i = 0;
        for(i = 0; i < _tokenIds.length; i = SafeMath.add(i, 1)) {
            totalAmountToBeTransferred = SafeMath.add(totalAmountToBeTransferred, tokensMapById[_tokenIds[i]].tokenAmount);
            _updateTokenAmount(_tokenIds[i], 0); // Set token amount to 0 after we transfer the token amount
        }
        uint256 newTokenId = _createToken(msg.sender, totalAmountToBeTransferred, tokenType, metadata);
        for(i = 0; i < _tokenIds.length; i = SafeMath.add(i, 1)) {
            emit Transfer(tokensMapById[_tokenIds[i]].tokenOwner, msg.sender, newTokenId);
        }
    }

    // Assigns the ownership of the POT with ID _tokenId to _to if and only if msg.sender == ownerOf(_tokenId).
    // A successful transfer MUST fire the Transfer event (defined below).
    // This method MUST transfer ownership to _to or throw, no other outcomes can be possible.
    function transfer(address _to, uint256 _tokenId, bytes[] sigs) public payable {
        require(msg.sender == tokensMapById[_tokenId].tokenOwner);
        require(_to != 0);
        _updateTokenOwner(_tokenId, _to);
    }

    // Returns the number of tokens (percentage of underlying mother asset) assigned to _owner.
    function balanceOf(address _owner) public view returns (uint256 _balance) {
        uint256 totalAmount = 0;
        for(uint256 i = 0; i < tokensMapByOwner[_owner].length; i = SafeMath.add(i, 1)) {
            totalAmount = SafeMath.add(totalAmount, tokensMapByOwner[_owner][i].tokenAmount);
        }
        return totalAmount;
        // return SafeMath.div(totalAmount, tokensMapByOwner[contractInstanceOwner][0].tokenAmount);
    }

    // Returns addresses of all owners currently holding POTs.
    function owners() public view returns (address[] _owners) {
        return uniqueOwners;
    }

    // Returns the address currently marked as the owner of _tokenId.
    // This method MUST throw if _tokenId does not represent a POT currently tracked by this contract.
    // This method MUST NOT return 0 (POTs assigned to the zero identity are considered destroyed, and queries about them should throw).
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        // Querying for 0 should throw as POT assigned to zero identity are conidered destroyed
        require(_tokenId != 0);
        // Throw if the token is not found
        require(tokensMapById[_tokenId].tokenId != 0);
        return tokensMapById[_tokenId].tokenOwner;
    }

    // Returns token data of _tokenId, if _tokenId represents POT currently tracked by this contract.
    function getToken(uint256 _tokenId) public view returns (address _owner, uint256 _amount, string _type, string _metadata) {
        return (tokensMapById[_tokenId].tokenOwner, tokensMapById[_tokenId].tokenAmount, tokensMapById[_tokenId].tokenType, tokensMapById[_tokenId].tokenMetadata);
    }

    // Returns number of tokens owned by _owner
    function totalTokens(address _owner) public view returns (uint256 _totalTokens) {
        return tokensMapByOwner[_owner].length;
    }

    // OPTIONAL - It is recommended that this method is implemented for enhanced usability,
    // but interfaces and other contracts MUST NOT depend on the existence of this method.
    // Returns the nth POT assigned to the _owner, with n specified by the _index argument.
    // This method MUST throw if _index >= totalTokens(_owner).
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId) {
        require(_index >= totalTokens(_owner));
        return tokensMapByOwner[_owner][_index].tokenId;
    }

    // identity hash
    function getIdentity(address _owner) public view returns (bytes32 _key) {
        return '';
    }

    // OPTIONAL
    // Returns the name of the token - e.g. "CryptoPremierLeague", "VirtualSmartFund".
    // OPTIONAL - This method can be used to improve usability, but interfaces and other
    // contracts MUST NOT expect these values to be present.
    function name() public constant returns (string _name) {
        return tokenName;
    }

    // Returns the symbol of the token. E.g. "CPL", "VSF".
    // OPTIONAL - This method can be used to improve usability, but interfaces and other
    // contracts MUST NOT expect these values to be present.
    function symbol() public constant returns (string _symbol) {
        return tokenSymbol;
    }

    // Returns the number of decimals the token uses - e.g. 8, means to divide the token
    // amount by 100000000 to get its user representation.
    // OPTIONAL - This method can be used to improve usability, but interfaces and other
    // contracts MUST NOT expect these values to be present
    function decimals() public pure returns (uint8 _decimals) {
        return 0;
    }

    // OPTIONAL - It is recommended that this method is implemented for enhanced usability, but interfaces
    // and other contracts MUST NOT depend on the existence of this method.
    // Returns a multiaddress string referencing an external resource bundle that contains
    // (optionally localized) metadata about the POT associated with _tokenId.
    // The string MUST be an IPFS or HTTP(S) base path (without a trailing slash) to which specific
    // subpaths are obtained through concatenation.
    // (IPFS is the preferred format due to better scalability, persistence, and immutability.) See ERC721
    function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl) {
        return tokensMapById[_tokenId].tokenMetadata;
    }
}