// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MeetingRoom {
    // Struct to define a meeting room with an ID, name, owner, and members
    struct Room {
        uint256 id;
        string name;
        address owner;
        address[] members;
    }
    
    // Struct to define a task with a description and completion status
    struct Task {
        string description;
        bool completed;
    }
    
    uint256 public roomCount; // Counter for the number of rooms
    mapping(uint256 => Room) public rooms; // Mapping room ID to Room struct
    mapping(uint256 => Task[]) public roomTasks; // Mapping room ID to list of tasks
    mapping(uint256 => mapping(address => bool)) public isMember; // Mapping to check if an address is a member of a room
    
    // Events for logging contract activity
    event RoomCreated(uint256 roomId, string name, address owner);
    event JoinedRoom(uint256 roomId, address member);
    event LeftRoom(uint256 roomId, address member);
    event TaskAdded(uint256 roomId, string description);
    event TaskCompleted(uint256 roomId, uint256 taskIndex);
    event OwnershipTransferred(uint256 roomId, address newOwner);
    event RoomDeleted(uint256 roomId);
    
    // Modifier to restrict access to room owners only
    modifier onlyOwner(uint256 _roomId) {
        require(msg.sender == rooms[_roomId].owner, "Not the room owner");
        _;
    }
    
    // Modifier to ensure function can only be called by room members
    modifier onlyMember(uint256 _roomId) {
        require(isMember[_roomId][msg.sender], "Not a room member");
        _;
    }
    
    // Modifier to ensure the room exists before performing an operation
    modifier roomExists(uint256 _roomId) {
        require(_roomId <= roomCount && _roomId != 0, "Room does not exist");
        _;
    }
    
    // Function to create a new meeting room
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
    
    // Function to join an existing room
    function joinRoom(uint256 _roomId) external roomExists(_roomId) {
        require(!isMember[_roomId][msg.sender], "Already a member");
        
        rooms[_roomId].members.push(msg.sender);
        isMember[_roomId][msg.sender] = true;
        
        emit JoinedRoom(_roomId, msg.sender);
    }
    
    // Function to leave a room (owner cannot leave)
    function leaveRoom(uint256 _roomId) external onlyMember(_roomId) {
        require(msg.sender != rooms[_roomId].owner, "Owner cannot leave the room");
        
        address[] storage members = rooms[_roomId].members;
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == msg.sender) {
                members[i] = members[members.length - 1]; // Replace with last member
                members.pop(); // Remove last member
                break;
            }
        }
        isMember[_roomId][msg.sender] = false;
        
        emit LeftRoom(_roomId, msg.sender);
    }
    
    // Function to add a task to a room (only owner can add tasks)
    function addTask(uint256 _roomId, string memory _description) external onlyOwner(_roomId) {
        roomTasks[_roomId].push(Task(_description, false));
        emit TaskAdded(_roomId, _description);
    }
    
    // Function to mark a task as completed (only owner can complete tasks)
    function completeTask(uint256 _roomId, uint256 _taskIndex) external onlyOwner(_roomId) {
        require(_taskIndex < roomTasks[_roomId].length, "Invalid task index");
        require(!roomTasks[_roomId][_taskIndex].completed, "Task already completed");
        
        roomTasks[_roomId][_taskIndex].completed = true;
        emit TaskCompleted(_roomId, _taskIndex);
    }
    
    // Function to transfer room ownership to another member
    function transferOwnership(uint256 _roomId, address _newOwner) external onlyOwner(_roomId) {
        require(_newOwner != address(0), "Invalid address");
        require(isMember[_roomId][_newOwner], "New owner must be a member");
        
        rooms[_roomId].owner = _newOwner;
        emit OwnershipTransferred(_roomId, _newOwner);
    }
    
    // Function to delete a room (only owner can delete)
    function deleteRoom(uint256 _roomId) external onlyOwner(_roomId) {
        delete rooms[_roomId];
        delete roomTasks[_roomId];
        emit RoomDeleted(_roomId);
    }
    
    // Function to get a list of all rooms
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
    
    // Function to get the list of members in a room
    function getRoomMembers(uint256 _roomId) external view roomExists(_roomId) returns (address[] memory) {
        return rooms[_roomId].members;
    }
    
    // Function to get the list of tasks in a room
    function getTasks(uint256 _roomId) external view roomExists(_roomId) returns (Task[] memory) {
        return roomTasks[_roomId];
    }
}
