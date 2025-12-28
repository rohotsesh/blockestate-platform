// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PropertyToken
 * @dev Token representing fractional ownership of a real estate property.
 */
contract PropertyToken is ERC20, Ownable {
    address public propertyRegistry;
    uint256 public propertyId;
    
    mapping(address => uint256) public votingPower;
    mapping(address => bool) public isAdmin;
    
    event PropertyTransferred(address indexed from, address indexed to, uint256 amount);
    event VotingPowerUpdated(address indexed voter, uint256 newPower);
    event AdminChanged(address indexed admin, bool isAdmin);
    
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
}