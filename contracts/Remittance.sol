pragma solidity ^0.4.4;

contract Remittance {
    address public owner;
    uint public fee;
    uint public duration;
    // uint public totalCommission;
    struct TransactionStruct {
        uint amount;
        uint deadline;
        address contributor;
        address receiver;
        bytes32 passwordsHx;
    }
    mapping(bytes32 => TransactionStruct) public transactions;
    
    function Remittance(uint _fee, uint _duration){
        owner = msg.sender;
        fee = _fee;
        duration = _duration;
    }
    
    function createFund(address receiver, bytes32 pw1, bytes32 pw2) 
        public 
        payable
        returns (bool success)
    {
        bytes32 hx = keccak256(pw1);
        bytes32 _passwordsHx = keccak256(pw1, pw2);
        
        TransactionStruct memory newTransaction;
        newTransaction.amount = msg.value;
        newTransaction.deadline = block.number + duration;
        newTransaction.contributor = msg.sender;
        newTransaction.receiver = receiver;
        newTransaction.passwordsHx = _passwordsHx;

        transactions[hx] = newTransaction;
        return true;
    }
    
    function checkAmount(bytes32 pw1)
        public
        returns(uint amount)
    {
        bytes32 hx = keccak256(pw1);
        require(transactions[hx].contributor == msg.sender || transactions[hx].receiver == msg.sender);
        return transactions[hx].amount;
        
    }
    
    function getPaid(bytes32 pw1, bytes32 pw2)
        public
        returns(bool success)
    {
        bytes32 hx = keccak256(pw1);
        bytes32 _passwordsHx = keccak256(pw1, pw2);
        
        require(transactions[hx].amount > 0);
        require(transactions[hx].receiver == msg.sender);
        // require(transactions[hx].deadline <= block.number);
        require(transactions[hx].passwordsHx == _passwordsHx);
        
        msg.sender.transfer(transactions[hx].amount);
        transactions[hx].amount = 0;
        return true;
    }

    
    function withDraw(bytes32 pw1, bytes32 pw2)
        public
        returns(bool success)
    {
        bytes32 hx = keccak256(pw1);
        bytes32 _passwordsHx = keccak256(pw1, pw2);
       
        require(transactions[hx].amount > 0);
        require(transactions[hx].contributor == msg.sender);
        // require(transactions[hx].deadline > block.number);
        require(transactions[hx].passwordsHx == _passwordsHx);
        
        msg.sender.transfer(transactions[hx].amount);
        
        transactions[hx].amount = 0;
        return true;
    }
    
    function kill() 
        public 
        returns(bool success)
    {
        require(msg.sender == owner);
        selfdestruct(owner);
        return true;
    }
    
    
}