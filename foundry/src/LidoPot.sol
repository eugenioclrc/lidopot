// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";

import {IStETH, IWstETH} from "./ILido.sol";

contract Raffle is Owned(msg.sender), ERC721("Ticket Lido POT", "LPOT") {
    uint256 public totalWsteth;
    uint256 public totalSteth;

    uint128[] public validTickets;
    uint128[] public burnedTickets;
    uint256 private _ticketCounterId;

    uint256 private immutable START_TICKET_PRICE_ETH; // in ether
    IStETH immutable STETH;
    IWstETH immutable WSTETH;

    constructor(uint256 _ticketPrice, address _WSTETH) {
        START_TICKET_PRICE_ETH = _ticketPrice;
        WSTETH = IWstETH(_WSTETH);
        STETH = IStETH(WSTETH.stETH());
    }

    function ticketPriceInSteth() public view returns (uint256) {
        if (validTickets.length > 0) {
            uint256 _totalSteth = STETH.getPooledEthByShares(WSTETH.getStETHByWstETH(totalWsteth));
            return _totalSteth / validTickets.length;
        }
        return START_TICKET_PRICE_ETH;
    }

    // @notice ticket price is in WStETH
    function ticketPrice() public view returns (uint256) {
        // calculate ticket price
        uint256 stethPrice = ticketPriceInSteth();
        return WSTETH.getWstETHByStETH(stethPrice);
    }

    function mint(uint256 amountTickets) external {
        // get ticket price
        uint256 priceSteth = ticketPriceInSteth();
        uint256 amountPriceWSTETH = amountTickets * priceSteth;

        totalWsteth += amountPriceWSTETH;
        totalSteth += priceSteth;

        WSTETH.transferFrom(msg.sender, address(this), amountPriceWSTETH);
        _safeMint(msg.sender, _ticketCounterId++);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(id < _ticketCounterId);
        // TODO
        return "";
    }
}
