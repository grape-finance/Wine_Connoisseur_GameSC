//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./VintageWine.sol";

contract VintageWineParty is Ownable {
    address public treasureWallet;

    struct Party {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        uint256 totalTickets;
        uint256 ticketPrice;
        uint256 initialPrize;
    }

    uint256 currentPartyId;
    mapping(uint256 => Party) public parties;

    struct Player {
        address owner;
        uint256 tickets;
    }

    mapping(uint256 => mapping(uint256 => Player)) public participantPlayers; // (Party Id, player Index) => player

    mapping(uint256 => mapping(address => uint256)) public playerIndex; // (Party Id, player address) => player index

    mapping(uint256 => uint256) public numberOfPlayers; // Party Id => total number of players

    VintageWine vintageWine;

    // Events
    event PartyCreated(
        uint256 id,
        uint256 startTime,
        uint256 endTime,
        uint256 ticketPrice,
        uint256 initialPrize
    );
    event PartyTicketBought(uint256 id, uint256 tickets);

    constructor(address _treasureWallet, VintageWine _vintageWine) {
        treasureWallet = _treasureWallet;
        vintageWine = _vintageWine;
    }

    function setVintageWine(VintageWine _vintageWine) external onlyOwner {
        vintageWine = _vintageWine;
    }

    function setTreasureWallet(address _treasureWallet) external onlyOwner {
        treasureWallet = _treasureWallet;
    }

    function createParty(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _ticketPrice,
        uint256 _initialPrize
    ) external onlyOwner {
        require(_endTime > 0, "Invalid end time");
        require(_ticketPrice > 0, "Invalid price amount");
        require(!partyActive(), "There is a party already.");
        currentPartyId++;
        Party storage party = parties[currentPartyId];
        party.id = currentPartyId;
        party.startTime = _startTime;
        party.endTime = _endTime;
        party.ticketPrice = _ticketPrice;
        party.initialPrize = _initialPrize;
        emit PartyCreated(
            party.id,
            party.startTime,
            party.endTime,
            party.ticketPrice,
            party.initialPrize
        );
    }

    // Needs to approve VintageWine first
    function buyTicket(uint256 _nrTickets) public {
        address owner = msg.sender;
        Party storage party = parties[currentPartyId];
        uint256 _amountVintageWine = _nrTickets * party.ticketPrice;
        require(partyActive(), "There is no active PARTY.");
        require(
            vintageWine.balanceOf(owner) >= _amountVintageWine,
            "not enough PIZZA"
        );

        vintageWine.transferFrom(
            address(owner),
            treasureWallet,
            _amountVintageWine
        );

        party.totalTickets += _nrTickets;

        if (playerIndex[currentPartyId][owner] == 0) {
            numberOfPlayers[currentPartyId]++;
            playerIndex[currentPartyId][owner] = numberOfPlayers[
                currentPartyId
            ];
            Player storage player = participantPlayers[currentPartyId][
                numberOfPlayers[currentPartyId]
            ];
            player.owner = owner;
            player.tickets += _nrTickets;
        } else {
            Player storage player = participantPlayers[currentPartyId][
                playerIndex[currentPartyId][owner]
            ];
            player.tickets += _nrTickets;
        }

        emit PartyTicketBought(currentPartyId, _nrTickets);
    }

    // Views
    function getPlayerTicket(address _player) public view returns (uint256) {
        Player memory player = participantPlayers[currentPartyId][
            playerIndex[currentPartyId][_player]
        ];
        return player.tickets;
    }

    function getTotalTickets() public view returns (uint256) {
        Party memory party = parties[currentPartyId];
        return party.totalTickets;
    }

    function getPlayers(
        uint256 partyId,
        uint256 _offset,
        uint256 _maxSize
    ) public view returns (Player[] memory) {
        if (_offset >= numberOfPlayers[partyId]) {
            return new Player[](0);
        }

        uint256 outputSize = _maxSize;
        if (_offset + _maxSize >= numberOfPlayers[partyId]) {
            outputSize = numberOfPlayers[partyId] - _offset;
        }
        Player[] memory outputs = new Player[](outputSize);

        for (uint256 i = 1; i <= outputSize; i++) {
            outputs[i - 1] = participantPlayers[partyId][i];
        }

        return outputs;
    }

    function currentParty() public view returns (Party memory) {
        Party memory party = parties[currentPartyId];
        return party;
    }

    function partyActive() public view returns (bool) {
        Party memory party = parties[currentPartyId];
        uint256 currentTimeStamp = block.timestamp;
        return
            currentTimeStamp >= party.startTime &&
            currentTimeStamp <= party.endTime;
    }
}
