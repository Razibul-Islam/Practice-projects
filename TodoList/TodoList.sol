// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract TodoList {
    struct Todo {
        string name;
        string description;
        bool finish;
        bool isDelete;
    }
    mapping(address => Todo[]) public lists;

    event TaskAdded(address user, string name);
    event CompletedTask(string name, bool finished);
    event DeleteTask(string name, bool deleted);

    function addTask(
        string calldata _name,
        string calldata _description
    ) public returns (bool) {
        lists[msg.sender].push(Todo(_name, _description, false, false));
        emit TaskAdded(msg.sender, _name);
        return true;
    }

    function marked(uint8 index) public {
        require(!lists[msg.sender][index].finish, "Already Finished");
        require(!lists[msg.sender][index].isDelete, "Already Deleted");

        Todo storage todo = lists[msg.sender][index];

        todo.finish = true;
        emit CompletedTask(todo.name, todo.finish);
    }

    function deleteTask(uint8[] calldata index) public {
        Todo[] storage todo = lists[msg.sender];
        for (uint256 i = 0; i < index.length; i++) {
            uint8 todoIndex = index[i];

            require(todoIndex < lists[msg.sender].length, "Invalid Index");
            require(!lists[msg.sender][todoIndex].isDelete, "Already Deleted");

            todo[todoIndex].isDelete = true;

            emit DeleteTask(todo[todoIndex].name, true);
        }
    }

    function getTodo() public view returns (Todo[] memory) {
        return lists[msg.sender];
    }
}
