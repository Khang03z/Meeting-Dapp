// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MeetingRoom {
    struct Room {
        uint256 id;
        string name;
        address owner;
        address[] members;
    }
    
    struct Task {
        string description;
        bool completed;
    }
    
    uint256 public roomCount;
    mapping(uint256 => Room) public rooms;
    mapping(uint256 => Task[]) public roomTasks;
    mapping(uint256 => mapping(address => bool)) public isMember;
    
    event RoomCreated(uint256 roomId, string name, address owner);
    event JoinedRoom(uint256 roomId, address member);
    event LeftRoom(uint256 roomId, address member);
    event TaskAdded(uint256 roomId, string description);
    event TaskCompleted(uint256 roomId, uint256 taskIndex);
    event OwnershipTransferred(uint256 roomId, address newOwner);
    event RoomDeleted(uint256 roomId);
    
    modifier onlyOwner(uint256 _roomId) {
        require(msg.sender == rooms[_roomId].owner, "Not the room owner");
        _;
    }
    
    modifier onlyMember(uint256 _roomId) {
        require(isMember[_roomId][msg.sender], "Not a room member");
        _;
    }
    
    modifier roomExists(uint256 _roomId) {
        require(_roomId <= roomCount && _roomId != 0, "Room does not exist");
        _;
    }
    
    function createRoom(string memory _name) external {
        roomCount++;
        Room storage room = rooms[roomCount];
        room.id = roomCount;
        room.name = _name;
        room.owner = msg.sender;
        room.members.push(msg.sender);
        isMember[roomCount][msg.sender] = true;
        
        emit RoomCreated(roomCount, _name, msg.sender);
    }
    
    function joinRoom(uint256 _roomId) external roomExists(_roomId) {
        require(!isMember[_roomId][msg.sender], "Already a member");
        
        rooms[_roomId].members.push(msg.sender);
        isMember[_roomId][msg.sender] = true;
        
        emit JoinedRoom(_roomId, msg.sender);
    }
    
    function leaveRoom(uint256 _roomId) external onlyMember(_roomId) {
        require(msg.sender != rooms[_roomId].owner, "Owner cannot leave the room");
        
        address[] storage members = rooms[_roomId].members;
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == msg.sender) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
        isMember[_roomId][msg.sender] = false;
        
        emit LeftRoom(_roomId, msg.sender);
    }
    
    function addTask(uint256 _roomId, string memory _description) external onlyOwner(_roomId) {
        roomTasks[_roomId].push(Task(_description, false));
        emit TaskAdded(_roomId, _description);
    }
    
    function completeTask(uint256 _roomId, uint256 _taskIndex) external onlyOwner(_roomId) {
        require(_taskIndex < roomTasks[_roomId].length, "Invalid task index");
        require(!roomTasks[_roomId][_taskIndex].completed, "Task already completed");
        
        roomTasks[_roomId][_taskIndex].completed = true;
        emit TaskCompleted(_roomId, _taskIndex);
    }
    
    function transferOwnership(uint256 _roomId, address _newOwner) external onlyOwner(_roomId) {
        require(_newOwner != address(0), "Invalid address");
        require(isMember[_roomId][_newOwner], "New owner must be a member");
        
        rooms[_roomId].owner = _newOwner;
        emit OwnershipTransferred(_roomId, _newOwner);
    }
    
    function deleteRoom(uint256 _roomId) external onlyOwner(_roomId) {
        delete rooms[_roomId];
        delete roomTasks[_roomId];
        emit RoomDeleted(_roomId);
    }
    
    function showListRoom() external view returns (uint256[] memory, string[] memory, uint256[] memory) {
    uint256[] memory ids = new uint256[](roomCount);
    string[] memory names = new string[](roomCount);
    uint256[] memory memberCounts = new uint256[](roomCount);

    for (uint256 i = 0; i < roomCount; i++) {
        ids[i] = rooms[i + 1].id;
        names[i] = rooms[i + 1].name;
        memberCounts[i] = rooms[i + 1].members.length;
    }

    return (ids, names, memberCounts);
    }

    function getRoomMembers(uint256 _roomId) external view roomExists(_roomId) returns (address[] memory) {
        return rooms[_roomId].members;
    }
    
    function getTasks(uint256 _roomId) external view roomExists(_roomId) returns (Task[] memory) {
        return roomTasks[_roomId];
    }
}