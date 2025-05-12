// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ShopJR {
    address public owner;
    uint256[] private productIds;

    struct Product {
        uint256 id;
        string name;
        string category;
        string description;
        string image;
        uint256 price;
        uint256 review;
        uint256 stock;
    }

    struct Order {
        Product product;
        uint256 orderTime;
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
        require(owner == msg.sender, "You are not the owenr");
        _;
    }

    function list(
        uint256 _id,
        string calldata _name,
        string calldata _category,
        string calldata _description,
        string memory _image,
        uint256 _price,
        uint256 _review,
        uint256 _stock
    ) public onlyOwner {
        Product memory product = Product(
            _id,
            _name,
            _category,
            _description,
            _image,
            _price,
            _review,
            _stock
        );

        require(products[_id].id != _id, "Product is already Exist.");

        products[_id] = product;
        productIds.push(_id);

        emit List(_name, _price, _stock);
    }

    function getProduct(uint256 id) public view returns (Product memory) {
        return products[id];
    }

    function getAllProduct() public view returns (Product[] memory) {
        Product[] memory allProduct = new Product[](productIds.length);
        for (uint256 i = 0; i < productIds.length; i++) {
            allProduct[i] = products[productIds[i]];
        }

        return allProduct;
    }

    function updateStock(uint256 id, uint256 newStock) public onlyOwner {
        products[id].stock += newStock;
    }

    function getMyOrders() public view returns (Order[] memory) {
        uint256 count = orderCount[msg.sender];
        Order[] memory order = new Order[](count);
        for (uint256 i = 0; i < count; i++) {
            order[i] = orders[msg.sender][i];
        }

        return order;
    }

    function buy(uint256 id) public payable {
        Product memory product = products[id];

        require(
            msg.value >= product.price,
            "You don't have sufficient balance"
        );

        require(product.stock > 0, "Sorry, this product is not available");

        Order memory order = Order(product, block.timestamp);
        orderCount[msg.sender]++;

        orders[msg.sender][orderCount[msg.sender]] = order;
        products[id].stock = product.stock - 1;

        emit Purchase(msg.sender, id, product.id);
    }

    function withdraw() public onlyOwner {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success);
    }
}
// 0xc14646261c04c7c8ace3ae1883b14998a2f51217