pragma solidity ^0.4.16;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './MintableToken.sol';
import './MultiOwnable.sol';


contract Crowdsale is MultiOwnable {
    using SafeMath for uint256;

    // Record contributors
    mapping (address => bool) contributors;
    uint256 contributorCount;

    // The token being sold
    MintableToken public token;

    // Address where funds are collected
    address public wallet;

    // Is finalized
    bool public isFinalized = false;

    // How much has been raised in WEI
    uint256 public raised = 0;

    // Hard cap for crowdsale in WEI
    uint256 public cap = 0;

    // https://github.com/OpenZeppelin/zeppelin-solidity/blob/1737555b0dda2974a0cd3a46bdfc3fb9f5b561b9/contracts/crowdsale/Crowdsale.sol#L40
    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
    */
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    /**
    * Event raised when crowd sale is finalized.
    */
    event Finalized();

    function Crowdsale(uint256 _eurToWei, address _token, address _wallet) {
        token = MintableToken(_token);
        wallet = _wallet;

        // (8,000,000 EUR * <eth-to-wei>) / <eur-to-wei>
        cap = 8000000000000000000000000 / _eurToWei;
    }

    // begin: Mon., Sep. 25, 2017 3:00:00 PM
    uint256 constant TIME_BEGIN = 1508943600;
    function rate() returns (uint256) {
        if (now < (TIME_BEGIN + 1 hours)) {
            // 1h: Mon., Sep. 25, 2017 4:00:00 PM
            return 12500; // 60%
        } else if (now < (TIME_BEGIN + 1 days)) {
            // 1d: Thu., Sep. 26, 2017 3:00:00 PM
            return 10000; // 50%
        } else if (now < (TIME_BEGIN + 3 days)) {
            // 3d: Thu., Sep. 28, 2017 3:00:00 PM
            return 8333; // 40%
        } else if (now < (TIME_BEGIN + 4 days)) {
            // 4d: Fri., Sep. 29, 2017 3:00:00 PM
            return 7692; // 35%
        } else if (now < (TIME_BEGIN + 5 days)) {
            // 5d: Sat., Sep. 30, 2017 3:00:00 PM
            return 7143; // 30%
        } else if (now < (TIME_BEGIN + 6 days)) {
            // 6d: Sun., Oct.  1, 2017 3:00:00 PM
            return 6849; // 27%
        } else if (now < (TIME_BEGIN + 7 days)) {
            // 7d: Mon., Oct.  2, 2017 3:00:00 PM
            return 6579; // 24%
        } else if (now < (TIME_BEGIN + 8 days)) {
            // 8d: Tue., Oct.  3, 2017 3:00:00 PM
            return 6410; // 22%
        } else {
            // 9d+
            return 6250; // 20%
        }
    }

    // https://github.com/OpenZeppelin/zeppelin-solidity/blob/1737555b0dda2974a0cd3a46bdfc3fb9f5b561b9/contracts/crowdsale/Crowdsale.sol#L64
    function () payable {
        buyTokens(msg.sender);
    }

    // https://github.com/OpenZeppelin/zeppelin-solidity/blob/1737555b0dda2974a0cd3a46bdfc3fb9f5b561b9/contracts/crowdsale/Crowdsale.sol#L69
    function buyTokens(address beneficiary) payable {
        require(beneficiary != 0x0);
        require(!isFinalized);

        uint256 amount = msg.value;
        require(amount != 0);

        // 1 ETH * 12500 (max-discount) = 12500000000000000000000 / 1 ether = 12500
        uint256 tokens = amount.mul(rate()).div(1 ether);

        raised += amount;

        token.mint(beneficiary, tokens);

        TokenPurchase(
            msg.sender,
            beneficiary,
            amount,
            tokens
        );

        wallet.transfer(amount);

        if (!contributors[beneficiary]) {
          contributors[beneficiary] = true;
          contributorCount += 1;
        }
    }

    // Get number of contributors
    function numberOfContributors() returns (uint256) {
      return contributorCount;
    }

    // https://github.com/OpenZeppelin/zeppelin-solidity/blob/1737555b0dda2974a0cd3a46bdfc3fb9f5b561b9/contracts/crowdsale/FinalizableCrowdsale.sol#L23
    function finalize() onlyOwner {
        require(!isFinalized);

        Finalized();

        isFinalized = true;
    }
}
