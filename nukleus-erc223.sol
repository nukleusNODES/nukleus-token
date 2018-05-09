pragma solidity ^0.4.23;

/**
 * @title SafeMath library
 * 
 **/

library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
* @title ERC20 interface
**/
interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _who) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns(bool);
    
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 *  @title ERC223 interface
 **/
interface ERC223 {
    
    /**
     *  View methods
     **/
    function balanceOf(address _owner) external view returns(uint256);
    function name() external view returns(string);
    function symbol() external view returns(string);
    function decimals() external view returns(uint8);
    
        
    function transfer(address _to, uint _value, bytes _data) external returns(bool);
    function transfer(address _to, uint _value, bytes _data, string __fallback) external returns(bool);
    
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

/**
 * @title ERC223 token handler
 **/
contract ERC223Receiver {
    function tokenFallback(address _fromm, uint256 _value, bytes _data) public pure;
}


/**
 * @title Contract Ownable
 **/ 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOWner);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 *  @title Contract Pauseable
 **/ 
contract Pauseable is Ownable {
    bool public paused = false;

    event Pause();
    event Unpause();

    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}


/**
 * @title Destructible 
 */
contract Destructible is Ownable {

  constructor() public payable { }

  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}


/**
 * @title NukleusToken contract
 **/
contract NukleusToken is ERC20, ERC223, Ownable, Pauseable, Destructible {
    
    using SafeMath for uint256;
    
    string private constant token_name = "NukTest";
    
    string private constant token_symbol = "Nkt";
    
    uint8 private constant token_decimals = 0;
    
    uint256 public constant INITIAL_SUPPLY = 21000000000;
    
    uint256 private totalSupply_;
    
    mapping(address => uint256) public balances;
    mapping (address => mapping (address => uint256)) internal allowed;       
    
    constructor() public {
        owner = msg.sender;		
		totalSupply_ = INITIAL_SUPPLY;
    	balances[owner] = INITIAL_SUPPLY;
        emit Transfer(0x0, owner, INITIAL_SUPPLY);
    }    
    
    function name() external view returns (string) {
        return token_name;
    }
    
    function symbol() external view returns (string) {
        return token_symbol;
    }
    
    function decimals() external view returns (uint8) {
        return token_decimals;
    }
    
    function totalSupply() external view returns (uint256) {
        return totalSupply_;
    }
    
    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }
    
    
    function isContract(address _addr) internal view returns (bool) {
        uint length;
        
        assembly {
            length := extcodesize(_addr)
        }
        
        return (length >0);
    }
    
    function transferToAddress(address _to, uint256 _value, bytes _data) private returns (bool) {
        require( _to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
	    balances[_to] = balances[_to].add(_value);
	    if (_data.length == 0) {
	        emit Transfer(msg.sender, _to, _value);
	    } else {
	        emit Transfer(msg.sender, _to, _value, _data);
	    }
        return true;
    }
    
    function transferToContract(address _to, uint256 _value, bytes _data) private returns (bool) {
        require( _to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
	    balances[_to] = balances[_to].add(_value);
	    
	    ERC223Receiver receiver = ERC223Receiver(_to);
	    receiver.tokenFallback(msg.sender, _value, _data);
	    if (_data.length == 0) {
	        emit Transfer(msg.sender, _to, _value);
	    } else {
	        emit Transfer(msg.sender, _to, _value, _data);
	    }
        return true;
        
    }

    function transfer(address _to, uint256 _value, bytes _data, string _fallback) external whenNotPaused returns (bool) {
        require( _to != address(0));
        require(_value <= balances[msg.sender]);
        
        if (isContract(_to)) {
            require(_value <= balances[msg.sender]);
            
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);

            assert(_to.call.value(0)(bytes4(keccak256(_fallback)), msg.sender, _value, _data));
            
            if (_data.length == 0) {
	            emit Transfer(msg.sender, _to, _value);
    	    } else {
    	        emit Transfer(msg.sender, _to, _value, _data);
    	    }
    	    return true;

        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

    function transfer(address _to, uint256 _value, bytes _data) external whenNotPaused returns (bool) {
        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

    function transfer(address _to, uint256 _value) external whenNotPaused returns (bool) {
        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) external whenNotPaused returns (bool status) {
	    bytes memory empty;
        if (isContract(_to)) {
            status =  transferToContract(_to, _value, empty);
        } else {
            status =  transferToAddress(_to, _value, empty);
        }
        if (status) {
	        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        }
	    return status;
	 }

	 function approve(address _spender, uint256 _value) external whenNotPaused returns (bool) {
	    allowed[msg.sender][_spender] = _value;
	    emit Approval(msg.sender, _spender, _value);
	    return true;
	 }

	function allowance(address _owner, address _spender) external view returns (uint256) {
    	return allowed[_owner][_spender];
  	}

  	function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool) {
	    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
	    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
	    return true;
	}

	function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool) {
	    uint oldValue = allowed[msg.sender][_spender];
	    if (_subtractedValue > oldValue) {
	      allowed[msg.sender][_spender] = 0;
	    } else {
	      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
	    }
	    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
	    return true;
	}

    /**
    * Burnable
    **/
    event Burn(address indexed burner, uint256 value);
	function burn(uint256 _value) public whenNotPaused {
	    require( msg.sender != address(0));
	    require(_value <= balances[msg.sender]);   
		address burner = msg.sender;
	    balances[burner] = balances[burner].sub(_value);
	    totalSupply_ = totalSupply_.sub(_value);
	    emit Burn(burner, _value);
	}
}
