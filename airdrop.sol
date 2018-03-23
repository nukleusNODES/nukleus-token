pragma solidity ^0.4.21;

interface NukTestToken {
    
    function transfer(address to, uint256 value) external returns (bool);
}


contract AirdropContract {
    
    address public owner;
    
    NukTestToken token;
   
    
    modifier onlyOwner() {
    	require(msg.sender == owner);
    	_;
  	}
    
    function AirdropContract() public {
      owner = msg.sender;
      token = NukTestToken(0xe151BE314861D5c22D2b014DB152c9DE3a0dd79D);
    }
    
    function send(address[] dests, uint256[] values) public onlyOwner returns(uint256) {
        uint256 i = 0;
        while (i < dests.length) {
            token.transfer(dests[i], values[i]);
            i += 1;
        }
        return i;
        
    }
    
    
}
