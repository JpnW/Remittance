pragma solidity ^0.4.4;

contract Remittance {
    address public owner;
    uint public fee;
    uint public duration;
    uint public totalCommission;
    struct TransactionStruct {
        uint amount;
        uint deadline;
        address contributor;
        address receiver;
        bytes32 passwordsHx;
    }
    mapping(bytes32 => TransactionStruct) public transactions;
    
    event createFundLog(address who, uint amount);
    event withDrawLog(address who, uint amount);
    event getPaidLog(address who, uint amount);
    event totalCommissionLog(address who, uint amount);
    

    function Remittance(uint _fee, uint _duration){
        owner = msg.sender;
        fee = _fee;
        require(_duration > 0);
        duration = _duration;
    }
    
    // Alice deposits fund and provides Carol's address and two passwords
    // the same password can't be used twice
    // a fixed fee is collected by contact owner
    function createFund(address receiver, bytes32 pw1, bytes32 pw2) 
        public 
        payable
        returns (bool success)
    {
        require(msg.value > fee);
        
        bytes32 hx = keccak256(pw1);
        bytes32 _passwordsHx = keccak256(pw1, pw2);
        
        require(transactions[hx].deadline == 0);
      
        TransactionStruct memory newTransaction;
        
        newTransaction.amount = msg.value - fee;
        newTransaction.deadline = block.number + duration;
        newTransaction.contributor = msg.sender;
        newTransaction.receiver = receiver;
        newTransaction.passwordsHx = _passwordsHx;
        
        transactions[hx] = newTransaction;
        
        totalCommission += fee;
        
        createFundLog(msg.sender, msg.value);
        
        return true;
    }
    
    // both Alice and Carol can check the amount that has been deposited
    function checkAmount(bytes32 pw1)
        public
        returns(uint amount)
    {
        bytes32 hx = keccak256(pw1);
        require(transactions[hx].contributor == msg.sender || transactions[hx].receiver == msg.sender);
        return transactions[hx].amount;
        
    }
    
    // After Carol gets the second password from Bob, 
    // Carol can get paid before the deadline 
    function getPaid(bytes32 pw1, bytes32 pw2)
        public
        returns(bool success)
    {
        bytes32 hx = keccak256(pw1);
        bytes32 _passwordsHx = keccak256(pw1, pw2);
        
        require(transactions[hx].amount > 0);
        require(transactions[hx].receiver == msg.sender);
        require(transactions[hx].deadline <= block.number);
        require(transactions[hx].passwordsHx == _passwordsHx);
        
        msg.sender.transfer(transactions[hx].amount);
        
        getPaidLog(msg.sender, transactions[hx].amount);
        
        transactions[hx].amount = 0;
        return true;
    }

    // Alice can withdraw the deposit after the deadline
    function withDraw(bytes32 pw1, bytes32 pw2)
        public
        returns(bool success)
    {
        bytes32 hx = keccak256(pw1);
        bytes32 _passwordsHx = keccak256(pw1, pw2);
       
        require(transactions[hx].amount > 0);
        require(transactions[hx].contributor == msg.sender);
        require(transactions[hx].deadline > block.number);
        require(transactions[hx].passwordsHx == _passwordsHx);
        
        msg.sender.transfer(transactions[hx].amount);
        
        withDrawLog(msg.sender, transactions[hx].amount);
        
        transactions[hx].amount = 0;
        return true;
    }
    
    // contract owner can kill the contract and receive commission
    function kill() 
        public 
        returns(bool success)
    {
        require(msg.sender == owner);
        totalCommissionLog(owner, totalCommission);
        selfdestruct(owner);
        return true;
    }
    
    
}
