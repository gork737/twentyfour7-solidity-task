pragma solidity 0.7.0;

import "./IERC20.sol";
import "./IMintableToken.sol";
import "./IDividends.sol";
import "./SafeMath.sol";

contract Token is IERC20, IMintableToken, IDividends {
  // ------------------------------------------ //
  // ----- BEGIN: DO NOT EDIT THIS SECTION ---- //
  // ------------------------------------------ //
  using SafeMath for uint256;
  uint256 public totalSupply;
  uint256 public decimals = 18;
  string public name = "Test token";
  string public symbol = "TEST";
  mapping (address => uint256) public balanceOf;
  // ------------------------------------------ //
  // ----- END: DO NOT EDIT THIS SECTION ------ //  
  // ------------------------------------------ //

  // IERC20
  mapping(address => mapping(address => uint256)) public override allowance;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  address[] public tokenHolders;
  mapping(address => uint256) public holderIndex;
  mapping(address => uint256) public withdrawableDividends;

  function transfer(address to, uint256 value) external override returns (bool) {
    _transfer(msg.sender, to, value); 
    return true;
  }

  function approve(address spender, uint256 value) external override returns (bool) {
    allowance[msg.sender][spender] = value; emit Approval(msg.sender, spender, value); 
    return true;
  }

  function transferFrom(address from, address to, uint256 value) external override returns (bool) {
    allowance[from][msg.sender] = allowance[from][msg.sender].sub(value); 
    _transfer(from, to, value); 
    return true;
  }

  function _transfer(address from, address to, uint256 value) internal {
  balanceOf[from] = balanceOf[from].sub(value);
  balanceOf[to] = balanceOf[to].add(value);
  _updateHolders(from);
  _updateHolders(to);
  emit Transfer(from, to, value);
}

  // IMintableToken

  function mint() external payable override {
    require(msg.value > 0, "No ETH"); 
    uint256 amount = msg.value; 
    totalSupply = totalSupply.add(amount); 
    balanceOf[msg.sender] = balanceOf[msg.sender].add(amount); 
    _updateHolders(msg.sender); 
    emit Transfer(address(0), msg.sender, amount);
  }

  function burn(address payable dest) external override {
    uint256 amount = balanceOf[msg.sender]; 
    require(amount > 0, "No balance"); 
    totalSupply = totalSupply.sub(amount); 
    balanceOf[msg.sender] = 0; 
    _updateHolders(msg.sender); 
    dest.transfer(amount); 
    emit Transfer(msg.sender, address(0), amount);
  }

  // IDividends

  function getNumTokenHolders() external view override returns (uint256) {
    return tokenHolders.length;
  }

  function getTokenHolder(uint256 index) external view override returns (address) {
    require(index > 0 && index <= tokenHolders.length, "Invalid index"); 
    return tokenHolders[index - 1];
  }

  function recordDividend() external payable override {
    require(msg.value > 0, "No ETH"); 
    uint256 total = totalSupply; 
    require(total > 0, "No supply"); 
    for (uint256 i = 0; i < tokenHolders.length; i++) { address holder = tokenHolders[i]; 
    uint256 share = balanceOf[holder].mul(msg.value).div(total); 
    withdrawableDividends[holder] = withdrawableDividends[holder].add(share); 
    }
  }

  function getWithdrawableDividend(address payee) external view override returns (uint256) {
    return withdrawableDividends[payee];
  }

  function withdrawDividend(address payable dest) external override {
    uint256 amount = withdrawableDividends[msg.sender]; 
    require(amount > 0, "No dividends"); 
    withdrawableDividends[msg.sender] = 0; 
    dest.transfer(amount);
  }
  function _updateHolders(address account) internal {
  if (balanceOf[account] == 0 && holderIndex[account] > 0) {
    uint256 index = holderIndex[account] - 1;
    uint256 lastIndex = tokenHolders.length - 1;
    address lastHolder = tokenHolders[lastIndex];
    tokenHolders[index] = lastHolder;
    holderIndex[lastHolder] = index + 1;
    tokenHolders.pop();
    holderIndex[account] = 0;
  } else if (balanceOf[account] > 0 && holderIndex[account] == 0) {
    tokenHolders.push(account);
    holderIndex[account] = tokenHolders.length;
  }
  }
}