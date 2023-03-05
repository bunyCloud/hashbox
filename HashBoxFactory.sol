// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import './HashBox.sol';

/**
 * @title Hash Box Factory
 * @dev Create an address book to store contacts and make transfers
 */
contract HashBoxFactory {
  uint256 public newBoxCost;
  uint256 public newPinCost;
  uint256 public txCost;
  address public owner;
  uint public ipfsCount = 0;
  uint public boxCount = 0;
  mapping(uint => Ipfs) public _ipfs;
  string public contractName = 'The Buny Project: HashBox Factory';
  mapping(address => HashBox) private hashBoxes;
  mapping(address => user) userList;
  mapping(address => box) boxList;

  // list of users
  struct user {
    string name;
    cid[] cidList;
    box[] boxList;
  }

  struct cid {
    string _ipfsHash;
    string _title;
  }

  struct box {
    string _boxName;
    address contractAddress;
  }

  struct Ipfs {
    uint id;
    string hash;
    string title;
    address author;
  }
  // event: ipfs cid/hash added
  event IpfsPinned(uint id, string hash, string title, address author);
  // event: new
  event HashBoxCreated(uint boxCount, string _boxName, address owner, address contractAddress);

  constructor() {
    owner = msg.sender;
    newBoxCost = 0.02 ether; // in avax
    txCost = 0.001 ether; // in avax
    newPinCost = 0.005 ether;
  }

  // MODIFIERS

  // Only the owner of the contract may call
  modifier onlyOwner() {
    require(msg.sender == owner, 'Only the contract owner may call this function');
    _;
  }

  // Register username to wallet address

  function createAccount(string calldata name) external {
    require(checkUserExists(msg.sender) == false, 'User already exists!');
    require(bytes(name).length > 0, 'Username cannot be empty!');
    userList[msg.sender].name = name;
  }

  // Returns the default name provided by an user
  function getUsername(address pubkey) external view returns (string memory) {
    require(checkUserExists(pubkey), 'User is not registered!');
    return userList[pubkey].name;
  }

  // check if username already exist
  function checkUserExists(address pubkey) public view returns (bool) {
    return bytes(userList[pubkey].name).length > 0;
  }

  // save content identifier to public contract
  function pinHash(string memory _ipfsHash, string memory _title) public payable {
    require(checkUserExists(msg.sender), 'Create an account first!');
    require(msg.value >= newPinCost, 'Not enough AVAX');
    require(bytes(_ipfsHash).length > 0);
    require(bytes(_title).length > 0);
    require(msg.sender != address(0));
    ipfsCount++;
    _ipfs[ipfsCount] = Ipfs(ipfsCount, _ipfsHash, _title, msg.sender);
    _pinHash(msg.sender, _ipfsHash, _title);
    // Trigger an event
    emit IpfsPinned(ipfsCount, _ipfsHash, _title, msg.sender);
  }

  // Create a new HashBox struct for this user
  function createHashBox(string memory _boxName) public payable returns (address contractAddress) {
    require(checkUserExists(msg.sender), 'Register username first!');
    require(msg.value >= newBoxCost, 'Not enough AVAX');
    boxCount++;
    HashBox newBox = new HashBox(msg.sender, _boxName);
    hashBoxes[msg.sender] = newBox;
    contractAddress = address(newBox);
    _createHashBox(msg.sender, _boxName, contractAddress);
    emit HashBoxCreated(boxCount, _boxName, msg.sender, contractAddress);
    return contractAddress;
  }

  // hash the hash helper function
  function _pinHash(address me, string memory _ipfsHash, string memory _title) internal {
    cid memory newCid = cid(_ipfsHash, _title);
    userList[me].cidList.push(newCid);
  }

  function _createHashBox(address me, string memory _boxName, address contractAddress) internal {
    box memory newBox = box(_boxName, contractAddress);
    userList[me].boxList.push(newBox);
  }

  function getMyBoxList() external view returns (box[] memory) {
    require(checkUserExists(msg.sender), 'Register a username first');
    return userList[msg.sender].boxList;
  }

  // fetch users uploaded cids
  function getMyCidList() external view returns (cid[] memory) {
    require(checkUserExists(msg.sender), 'Create an account first!');
    return userList[msg.sender].cidList;
  }

  // Return this user's Hash Box contract address
  function fetchHashBox() public view returns (HashBox userData) {
    userData = hashBoxes[msg.sender];
    return userData;
  }

  function updatePinCost(uint256 _pinCost) public onlyOwner {
    newPinCost = _pinCost;
  }

  // Update the price to open an account here
  function updateBoxCost(uint256 _accountOpenCost) public onlyOwner {
    newBoxCost = _accountOpenCost;
  }

  // Update the price to interact with this contract
  function updateTransactionCost(uint256 _txCost) public onlyOwner {
    txCost = _txCost;
  }

  // PAYMENT FUNCTIONS
  function checkBalance() public view onlyOwner returns (uint256 amount) {
    amount = address(this).balance;
    return amount;
  }

  // Withdraw contract balance
  function withdraw() public onlyOwner {
    (bool sent, ) = msg.sender.call{ value: checkBalance() }('');
    require(sent, 'There was a problem while withdrawing');
  }
}
