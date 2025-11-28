// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @title Mechanical Temp Payment Portal (USDC)
 * @dev Secure contract for accepting USDC payments on Arbitrum.
 */
contract MechanicalTempPayments is Ownable {
    IERC20 public usdcToken;
    uint256 public totalRevenue; // In USDC units (6 decimals)

    event InvoicePaid(string invoiceId, address indexed customer, uint256 amount, uint256 timestamp);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event TokenUpdated(address oldToken, address newToken);

    // Deploy with Arbitrum USDC Address: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831
    constructor(address _usdcTokenAddress) {
        usdcToken = IERC20(_usdcTokenAddress);
    }

    /**
     * @notice Pay an invoice with USDC
     * @dev Customer must approve this contract to spend their USDC first!
     * @param _invoiceId The ID of the invoice being paid
     * @param _amount The amount of USDC to pay (6 decimals)
     */
    function payInvoice(string memory _invoiceId, uint256 _amount) external {
        require(_amount > 0, "Amount must be > 0");
        
        // Transfer USDC from Customer to this Contract
        bool success = usdcToken.transferFrom(_msgSender(), address(this), _amount);
        require(success, "USDC Transfer failed. Check allowance?");

        // Track Revenue
        totalRevenue += _amount;

        // Emit Receipt
        emit InvoicePaid(_invoiceId, _msgSender(), _amount, block.timestamp);
    }

    /**
     * @notice Withdraw all USDC to the owner (Bank Vault)
     */
    function withdrawFunds() external onlyOwner {
        uint256 balance = usdcToken.balanceOf(address(this));
        require(balance > 0, "No funds to withdraw");

        bool success = usdcToken.transfer(owner(), balance);
        require(success, "Transfer failed");

        emit FundsWithdrawn(owner(), balance);
    }
    
    /**
     * @notice Update the token address if USDC migrates or changes
     */
    function setUsdcToken(address _newToken) external onlyOwner {
        emit TokenUpdated(address(usdcToken), _newToken);
        usdcToken = IERC20(_newToken);
    }
}
