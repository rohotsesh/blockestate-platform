// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PropertyToken
 * @dev Token representing fractional ownership of a real estate property.
 * Includes governance features for decision-making by token holders.
 */
contract PropertyToken is ERC20, Ownable {
    address public propertyRegistry;
    uint256 public propertyId;
    string public jurisdiction = "Switzerland"; // Default jurisdiction
    
    mapping(address => uint256) public votingPower;
    mapping(address => bool) public isAdmin;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public hasVoted;
    
    uint256 public proposalCount;
    uint256 public constant VOTE_THRESHOLD = 50; // 50% of total supply needed to pass
    
    struct Proposal {
        address proposer;
        string description;
        uint256 voteDeadline;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }
    
    event PropertyTransferred(address indexed from, address indexed to, uint256 amount);
    event VotingPowerUpdated(address indexed voter, uint256 newPower);
    event AdminChanged(address indexed admin, bool isAdmin);
    event ProposalCreated(uint256 indexed proposalId, address proposer, string description);
    event VoteCast(uint256 indexed proposalId, address voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);
    event JurisdictionChanged(string newJurisdiction);
    
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address initialOwner,
        address _propertyRegistry,
        uint256 _propertyId
    ) ERC20(name, symbol) Ownable(initialOwner) {
        propertyRegistry = _propertyRegistry;
        propertyId = _propertyId;
        _mint(initialOwner, initialSupply);
        isAdmin[initialOwner] = true;
    }
    
    function transfer(address to, uint256 amount) public override returns (bool) {
        require(to != address(0), "PropertyToken: transfer to zero address");
        _transfer(msg.sender, to, amount);
        emit PropertyTransferred(msg.sender, to, amount);
        return true;
    }
    
    function transferWithVoting(address to, uint256 amount, bool transferVotingPower) external returns (bool) {
        require(to != address(0), "PropertyToken: transfer to zero address");
        _transfer(msg.sender, to, amount);
        if (transferVotingPower) {
            votingPower[to] = votingPower[to] + votingPower[msg.sender];
            votingPower[msg.sender] = 0;
        }
        emit PropertyTransferred(msg.sender, to, amount);
        return true;
    }
    
    function updateVotingPower(address voter, uint256 newPower) external onlyOwner {
        votingPower[voter] = newPower;
        emit VotingPowerUpdated(voter, newPower);
    }
    
    function setAdmin(address admin, bool status) external onlyOwner {
        isAdmin[admin] = status;
        emit AdminChanged(admin, status);
    }
    
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
    
    // Governance functions
    function createProposal(string memory description, uint256 votingPeriod) external returns (uint256) {
        require(balanceOf(msg.sender) > 0, "Must hold tokens to propose");
        proposalCount++;
        proposals[proposalCount] = Proposal({
            proposer: msg.sender,
            description: description,
            voteDeadline: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });
        emit ProposalCreated(proposalCount, msg.sender, description);
        return proposalCount;
    }
    
    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp <= proposal.voteDeadline, "Voting period ended");
        require(!hasVoted[msg.sender][proposalId], "Already voted");
        uint256 weight = votingPower[msg.sender];
        require(weight > 0, "No voting power");
        
        if (support) {
            proposal.yesVotes += weight;
        } else {
            proposal.noVotes += weight;
        }
        hasVoted[msg.sender][proposalId] = true;
        emit VoteCast(proposalId, msg.sender, support, weight);
    }
    
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.voteDeadline, "Voting still ongoing");
        require(!proposal.executed, "Already executed");
        require(proposal.yesVotes > proposal.noVotes, "Proposal did not pass");
        require(proposal.yesVotes * 100 / totalSupply() >= VOTE_THRESHOLD, "Insufficient turnout");
        
        // Placeholder for execution logic
        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }
    
    function changeJurisdiction(string memory newJurisdiction) external onlyOwner {
        jurisdiction = newJurisdiction;
        emit JurisdictionChanged(newJurisdiction);
    }
    
    // Emergency admin function to force transfer tokens in case of dispute
    function forceTransfer(address from, address to, uint256 amount) external {
        require(isAdmin[msg.sender], "Not admin");
        _transfer(from, to, amount);
        emit PropertyTransferred(from, to, amount);
    }
    
    // Dispute resolution clause (off-chain reference)
    function disputeResolution() external pure returns (string memory) {
        return "Any disputes shall be resolved by arbitration in the jurisdiction specified.";
    }
}