// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RJShop {
    address public owner;

    struct Product {
        uint256 id;
        string name;
        string category;
        string image;
        uint256 price;
        uint256 review;
        uint256 stock;
    }

    struct Order {
        uint256 orderTime;
        Product product;
    }

    mapping(uint256 => Product) private products;
    mapping(address => mapping(uint256 => Order)) private orders;
    mapping(address => uint256) private orderCount;

    event Purchase(address buyer, uint256 orderId, uint256 productId);
    event List(string name, uint256 price, uint256 quantity);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    function list(
        uint256 _id,
        string calldata _name,
        string calldata _category,
        string calldata _image,
        uint256 _price,
        uint256 _review,
        uint256 _stock
    ) public onlyOwner {
        Product memory product = Product(
            _id,
            _name,
            _category,
            _image,
            _price,
            _review,
            _stock
        );

        products[_id] = product;

        emit List(_name, _price, _stock);
    }

    function buy(uint256 _id) public payable  {
        Product memory product = products[_id];

        require(
            msg.value >= product.price,
            "You don't have sufficient balance"
        );

        require(product.stock > 0,"Sorry, The product is not available");

        Order memory order = Order(block.timestamp,product);
        orders[msg.sender][orderCount[msg.sender]] = order;

        products[_id].stock = product.stock -1;

        emit Purchase(msg.sender, orderCount[msg.sender], product.id);
    }

    function withdraw() public onlyOwner{
        (bool success,) = owner.call{value: address(this).balance}("");
        require(success);
    }

    
}
// 0xa5a24273bef96c6425e5066e1c07a027eb19d79d