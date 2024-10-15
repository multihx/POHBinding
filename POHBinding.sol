// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract POHBinding {
    mapping(address => bytes32) public pohMap;
    mapping(address => bool) public whitelistMap;

    address owner;

    event WhitelistUpdated(address indexed user, bool status);
    event Bound(address indexed user, bytes32 data);
    event Rebound(
        address indexed oldAddr,
        address indexed newAddr,
        bytes32 oldData,
        bytes32 newData
    );

    constructor() {
        owner = msg.sender;
        whitelistMap[owner] = true;
    }

    function updateWhitelist(address _user, bool _status) external {
        require(msg.sender != owner, "Only owner can call this function");
        whitelistMap[_user] = _status;
        emit WhitelistUpdated(_user, _status);
    }

    function bindAddress(address _addr, bytes32 _data) external {
        require(whitelistMap[msg.sender], "Caller is not whitelisted");
        pohMap[_addr] = _data;

        emit Bound(_addr, _data);
    }

    function rebind(
        address _oldAddr,
        address _newAddr,
        bytes32 _newData
    ) external {
        require(whitelistMap[msg.sender], "Caller is not whitelisted");
        require(pohMap[_oldAddr] != bytes32(0), "No binding for address");
        emit Rebound(_oldAddr, _newAddr,pohMap[_oldAddr], _newData);
        
        delete pohMap[_oldAddr];
        pohMap[_newAddr] = _newData;
    }

    function getData(address _addr) external view returns (bytes32) {
        require(pohMap[_addr] != bytes32(0), "No binding for address");
        return pohMap[_addr];
    }
}
