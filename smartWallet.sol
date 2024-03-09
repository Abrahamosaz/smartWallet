// SPDX-License-Identifier: MIT


pragma solidity ^0.8.14;

contract Consumer {

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function deposit() public payable {}
}

contract SmartWallet {
    address payable public owner;
    mapping(address => uint) public allowance;
    mapping(address => bool) public isAllowedToSend;
    mapping(address => bool) public guardians;
    mapping(address =>  mapping(address => bool)) guardianNextOwnerVotedBool;
    mapping(address => next) nextOwnerDetails;
    // uint guardianResetCount;
    uint guardiansCount;
    // address payable public nextOwner;
    uint guardiansMaxLimit = 5;
    uint guardiansAllowableLimitForChange = 3;


    struct next {
        address payable nextOwner;
        uint8 nextVotedCount;
    }


    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {}


    function  getbalance() public view returns(uint) {
        return address(this).balance;
    }

    function SetGuadians(address _for, bool isGuardian) public {
        require(owner == msg.sender, "you are not the owner of this wallet, aborting");
        require(guardiansCount <=  guardiansMaxLimit, "you have reach the max number of guardians for this wallet, aborting");
        guardians[_for] = isGuardian;
        guardiansCount++;

    }

    function removeGuardian(address _for) public {
        require(owner == msg.sender, "you are not the owner of this wallet, aborting!"); 
        if (guardiansCount > 0) {
            guardians[_for] = false;
            guardiansCount--;
        }
    }


    function setNewOwner(address payable _newOwner) public  {
        require(guardians[msg.sender], "you are not a guardian for this wallet, aborting!");
        require(guardianNextOwnerVotedBool[_newOwner][msg.sender] == false, "you already voted for this address, aborting!");

        if (_newOwner != nextOwnerDetails[_newOwner].nextOwner) {
            nextOwnerDetails[_newOwner].nextOwner = _newOwner;
            nextOwnerDetails[_newOwner].nextVotedCount = 0;
            guardianNextOwnerVotedBool[_newOwner][msg.sender] = true;
        }
        
        nextOwnerDetails[_newOwner].nextVotedCount++;

        if (nextOwnerDetails[_newOwner].nextVotedCount >= guardiansAllowableLimitForChange) {
            owner = nextOwnerDetails[_newOwner].nextOwner;
            nextOwnerDetails[_newOwner].nextOwner = payable(address(0));
        }
    }


    function setAllowance(address _for, uint _amount) public {
        require(owner == msg.sender, "you are not the owner, aborting!");
        allowance[_for] = _amount;

        if (_amount > 0) {
            isAllowedToSend[_for] = true;
        } else {
            isAllowedToSend[_for] = false;
        }

    }

    function transfer(address _to, uint _amount, bytes memory _payload) public returns(bytes memory) {
        if (owner != msg.sender) {
            require(isAllowedToSend[msg.sender], "you are not allowed to send funds from this smart contract, aborting!");
            require(allowance[msg.sender] >= _amount, "you are trying to send funds that is more then your allowance, aborting!");
        }


        (bool success, bytes memory data) = _to.call{value: _amount}(_payload);
        require(success, "aborting, call was not successfull!");

        return data;
    }
}