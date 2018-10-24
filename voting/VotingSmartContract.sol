pragma solidity ^0.4.4;

contract VotingSmartContract {
    // Vote
    struct Vote {
        string entity_id;
        address voter;
        bool vote;
        uint period;
        uint stake;
    }
    // Entity
    struct Entity {
        string id;
        string name;
        uint start_time;
        uint reward;
        uint stake;
        Vote[] votes;
        bool outcome1;
        bool outcome2;
        bool outcome;
    }
    
    address owner;
    Entity[] entities;
    mapping(string => Entity) entity_map;
    
    constructor() public {
        owner = msg.sender;
    }
    
    // The smart contract must allow the user to change the owner
    function changeOwner(address new_owner) public {
        require(owner == msg.sender);
        owner = new_owner;
    }
    
    // The smart contract will store multiple entities in the smart contract.
    function createEntity(string id, string name, uint start_time, uint reward) public {
        // The owner of the smart contract can add a new entity to the list of available entities.
        require(owner == msg.sender);
        entity_map[id].id = id;
        entity_map[id].name = name;
        entity_map[id].start_time = start_time;
        entity_map[id].reward = reward;
        entity_map[id].stake = 0;
        entities.push(entity_map[id]);
    }
    
    // The smart contract must allow transfer of tokens. (via payable keyword)
    function vote(string entity_id, uint period, bool vote_selection) public payable {
        // A wallet can only vote once EVER on an entity.
        uint voterVoteCount = 0;
        for (uint i = 0; i < entity_map[entity_id].votes.length; i += 1) {
            if (entity_map[entity_id].votes[i].voter == msg.sender) {
                voterVoteCount += 1;
            }
        }
        require(voterVoteCount == 0);
        
        entity_map[entity_id].votes.push(Vote({entity_id: entity_id, voter: msg.sender, vote: vote_selection, period: period, stake: msg.value}));
        entity_map[entity_id].stake += msg.value;
    }
    
    // The smart contract must implement a public function which returns how many people voted YES on a specific entity
    // The smart contract must implement a public function which returns how many people voted NO on a specific entity.
    function voteCount(string entity_id, bool vote_selection) public constant returns (uint) {
        uint count = 0;
        for (uint i = 0; i < entity_map[entity_id].votes.length; i += 1) {
            if (entity_map[entity_id].votes[i].vote == vote_selection) {
                count += 1;
            }
        }
        
        return count;
    }
}