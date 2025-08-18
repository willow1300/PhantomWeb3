// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
  Inlined minimal OpenZeppelin-style ERC20 + Ownable (adapted) plus Uniswap V2 interfaces
  and the JEFE token contract. This lets you compile without external imports from node_modules.
*/

/*** Uniswap V2 interfaces (local, with SPDX header) ***/

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


/*** Minimal OpenZeppelin-like ERC20 and Ownable implementations (adapted) ***/

// Simple Context
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked { _approve(sender, _msgSender(), currentAllowance - amount); }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked { _approve(_msgSender(), spender, currentAllowance - subtractedValue); }
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked { _balances[from] = fromBalance - amount; }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked { _balances[account] = accountBalance - amount; }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/*** JEFE token (updated to override _transfer rather than a non-standard _update) ***/

contract JEFE is ERC20, Ownable {
    IUniswapV2Router02 public immutable router;
    address public pair;
    address public vault;
    uint256 public taxFee = 2;
    uint256 public liqFee = 1;
    uint256 public vaultFee = 2;
    uint256 public maxTx;
    bool private swapping;
    bool public pairCreated = false;

    modifier lock() {
        swapping = true;
        _;
        swapping = false;
    }

    constructor(address _router) ERC20("JFFE TOKEN", unicode"JÉFE") {
        require(_router != address(0), "Router address is zero");
        router = IUniswapV2Router02(_router);

        // Mint 1 billion tokens with 18 decimals
        uint256 totalTokens = 1e15 * 1e18;
        _mint(_msgSender(), totalTokens);
        maxTx = totalTokens * 3 / 1000;  // 0.3% max transaction
    }

    // Create pair after deployment
    function createPair() external onlyOwner {
        require(pair == address(0), "Pair already created");

        address factory = router.factory();
        address weth = router.WETH();

        pair = IUniswapV2Factory(factory).createPair(address(this), weth);
        pairCreated = true;
    }

    function setVault(address _vault) external onlyOwner {
        require(_vault != address(0), "Invalid vault address");
        vault = _vault;
    }

    function setFees(uint256 _tax, uint256 _liq, uint256 _vault) external onlyOwner {
        taxFee = _tax;
        liqFee = _liq;
        vaultFee = _vault;
    }

    function setMaxTx(uint256 _percent) external onlyOwner {
        require(_percent > 0 && _percent <= 100, "Invalid percentage");
        maxTx = totalSupply() * _percent / 100;
    }

    receive() external payable {}

    // Override OpenZeppelin _transfer hook to implement fees on sells
    function _transfer(address from, address to, uint256 amount) internal virtual override {
        // Allow if transferring from zero (shouldn't normally happen) - delegate to super
        if (from == address(0)) {
            super._transfer(from, to, amount);
            return;
        }

        require(amount <= maxTx || from == owner() || to == owner(), "Exceeds max tx");

        // Only apply fees if pair is created and it's a sell (to == pair)
        if (pairCreated && !swapping && to == pair) {
            uint256 vaultAmt = amount * vaultFee / 100;
            uint256 liqAmt = amount * liqFee / 100;
            uint256 taxAmt = amount * taxFee / 100;
            uint256 totalDeducted = vaultAmt + liqAmt + taxAmt;

            // Transfer fees
            if (vaultAmt > 0) {
                super._transfer(from, vault, vaultAmt);
            }
            if (liqAmt + taxAmt > 0) {
                super._transfer(from, address(this), liqAmt + taxAmt);
            }

            // Add liquidity with the liquidity portion
            if (liqAmt > 0) {
                _addLiquidity(liqAmt);
            }

            // Update amount to send to recipient
            amount -= totalDeducted;
        }

        super._transfer(from, to, amount);
    }

    function _addLiquidity(uint256 tokenAmt) private lock {
        // Approve router to spend tokens from this contract
        _approve(address(this), address(router), tokenAmt);
        uint256 half = tokenAmt / 2;

        // Swap half for ETH
        address[] memory path = _path();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            half,
            0,
            path,
            address(this),
            block.timestamp
        );

        // Add liquidity with the other half and the ETH obtained
        router.addLiquidityETH{value: address(this).balance}(
            address(this),
            tokenAmt - half,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function _path() private view returns (address[] memory) {
        address[] memory p = new address[](2);
        p[0] = address(this);
        p[1] = router.WETH();
        return p;
    }
}
