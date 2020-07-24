pragma solidity 0.4.26;

import "SafeMath.sol";


contract FungibleToken {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private _totalSupply;

    mapping (address => uint256) private _balances;
    event LogMint(address indexed to, uint256 amount);
    event LogBurn(address indexed to, uint256 amount);

    constructor(
        string _name,
        string _symbol,
        uint8 _decimals
    ) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _totalSupply = 0;
    }

    function mint(
        address _to,
        uint256 _value
    ) external returns (bool) {
        _balances[_to] = _balances[_to].add(_value);
        _totalSupply = _totalSupply.add(_value);
        emit LogMint(_to, _value);
        return true;
    }

    function burn(
        address _from,
        uint256 _value
    ) external returns (bool) {
        require(_value <= _balances[_from]);
        _balances[_from] = _balances[_from].sub(_value);
        emit LogBurn(_from, _value);
        return true;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _balances[owner];
    }
}
