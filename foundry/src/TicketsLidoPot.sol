// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";

import {IStETH, IWstETH} from "./ILido.sol";

import {console} from "forge-std/console.sol";

contract TicketsLidoPot is Owned(msg.sender), ERC721("Ticket Lido POT", "LPOT") {
    uint256 public totalWsteth;
    uint256 public totalSteth;

    uint256[] public validTickets;
    uint256[] public burnedTickets;
    uint256 private _ticketCounterId;

    uint256 private immutable START_TICKET_PRICE_STETH; // in stETH
    IStETH immutable STETH;
    IWstETH immutable WSTETH;

    uint256 lastRaffleTimestamp;

    uint256 raffleProbabilities = 100_00;
    // probably will change this for testing
    uint256 RAFFLE_INTERVAL = 1 days;

    event Winner(uint256 winnerTicket);
    event Rebase(uint256 pricePool);

    constructor(uint256 _ticketPriceSTETH, address _WSTETH) {
        START_TICKET_PRICE_STETH = _ticketPriceSTETH;
        WSTETH = IWstETH(_WSTETH);
        STETH = IStETH(WSTETH.stETH());

        STETH.approve(_WSTETH, type(uint256).max);
    }

    function ticketPriceInSteth() public view returns (uint256) {
        if (validTickets.length == 0) {
            return START_TICKET_PRICE_STETH;
        }

        return WSTETH.getStETHByWstETH(ticketPrice());
    }

    // @notice ticket price is in WStETH
    // @return ticket price in WStETH
    function ticketPrice() public view returns (uint256) {
        // calculate ticket price
        if (totalWsteth == 0) {
            return WSTETH.getWstETHByStETH(START_TICKET_PRICE_STETH);
        }
        return totalWsteth / validTickets.length;
    }

    function mint(uint256 amountTickets) external {
        if (validTickets.length == 0) {
            lastRaffleTimestamp = block.timestamp;
        }
        // get ticket price
        uint256 priceSteth = ticketPriceInSteth();
        uint256 amountPriceWSTETH = amountTickets * priceSteth;

        totalWsteth += amountPriceWSTETH;
        totalSteth += amountTickets * priceSteth;

        STETH.transferFrom(msg.sender, address(this), amountTickets * priceSteth);
        WSTETH.wrap(amountPriceWSTETH);

        while (burnedTickets.length > 0 && amountTickets > 0) {
            uint256 ticketId = burnedTickets[burnedTickets.length - 1];
            burnedTickets.pop();
            validTickets.push(ticketId);
            _mint(msg.sender, ticketId);
            amountTickets--;
        }

        while (amountTickets > 0) {
            _ticketCounterId++;
            _mint(msg.sender, _ticketCounterId);
            validTickets.push(_ticketCounterId);
            amountTickets--;
        }
    }

    // @notice only owner can burn (some one with permission to the token cant burn)
    function burn(uint256 id) public {
        require(ownerOf(id) == msg.sender);
        uint256 price = ticketPrice(); //price in WSTETH
        uint256 priceSteth = WSTETH.getStETHByWstETH(price);
        totalWsteth -= price;
        totalSteth -= priceSteth;
        // remove ticket id from validTickets

        _removeTicket(id);
        uint256 val = WSTETH.unwrap(price);
        STETH.transfer(msg.sender, val);
        _burn(id);
    }

    // burn multiple tickets
    function burn(uint256[] calldata ids) external {
        for (uint256 i = 0; i < ids.length; i++) {
            burn(ids[i]);
        }
    }

    function _removeTicket(uint256 id) internal {
        uint256[] storage _validTickets = validTickets; // copy to memory for gas efficiency
        for (uint256 i = 0; i < _validTickets.length; i++) {
            if (_validTickets[i] == id) {
                _validTickets[i] = _validTickets[_validTickets.length - 1];
                _validTickets.pop();
                burnedTickets.push(id);
                return;
            }
        }
    }

    function pricePool() public view returns (uint256) {
        if (totalWsteth == 0) return 0;
        console.log(WSTETH.getStETHByWstETH(totalWsteth), totalSteth);

        return WSTETH.getStETHByWstETH(totalWsteth) - totalSteth;
    }

    // @audit INSECURE FUNCTION, only valid for a hackaton MVP
    function raffle() external {
        require(validTickets.length > 0, "No tickets");
        require(lastRaffleTimestamp + RAFFLE_INTERVAL < block.timestamp, "Raffle not ready, wait one day");

        uint256 _pricePool = pricePool();
        require(_pricePool > 0, "no price to be award");

        uint256 randomNumber = uint256(blockhash(block.number - 1));
        // raffleProbabilities is the probability of doing a raffle
        if (randomNumber % 100_00 < raffleProbabilities) {
            // Do the raffle
            uint256 winnerTicket = validTickets[randomNumber % validTickets.length];
            address winner = ownerOf(winnerTicket);
            uint256 priceSTETH = WSTETH.unwrap(WSTETH.getWstETHByStETH(_pricePool));

            // priceSTETH should be equal to _pricePool
            STETH.transfer(winner, priceSTETH);

            emit Winner(winnerTicket);
        } else {
            // Rebase ticket prices
            totalSteth += _pricePool;
            emit Rebase(_pricePool);
        }
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(id < _ticketCounterId);
        // TODO
        return "";
    }

    function setRaffleProbabilities(uint256 newVal) external onlyOwner {
        require(newVal <= 100_00, "invalid number");
        raffleProbabilities = newVal;
    }

    function setRaffleInterval(uint256 interval) external onlyOwner {
        RAFFLE_INTERVAL = interval;
    }
}
