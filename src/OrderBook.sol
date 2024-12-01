// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;
import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';

contract OrderBook {
    
    enum OrderStatus {
        OPEN,
        FILLED,
        CLOSED,
        PARTIALLY_FILLED
    }
    
    struct OrderFills {
        address buyer;
        uint256 amount;
    }

    struct Order {
        uint256 id;
        address tokenIn;
        address tokenOut;
        uint price;
        uint quantity;
        OrderStatus status;
        OrderFills[] buyers;
    }

    IERC20[] public tokens;
    mapping(address => Order[]) public creatorToOrder;
    mapping(uint256 => uint256) public idToOrder;
    Order[] orderList;
    Order[] operOrders;
    uint256 orderID = 0;

    function addOrder(address tokenIn, address tokenOut, uint256 price, uint256 quantity) public {
        Order memory order = Order(orderID, tokenIn, tokenOut, price, quantity, OrderStatus.OPEN, new OrderFills[](0));
        
        for (uint i = 0; i < orderList.length; i++) {
            if (orderList[i].tokenIn == tokenIn && orderList[i].tokenOut == tokenOut) {

            }
        }
        
        creatorToOrder[msg.sender].push(order);
        idToOrder[orderID] = orderID;
        orderList.push(order);
        orderID++;
    }

    function getOrders(address user) public view returns (Order[] memory) {
        return _filter_orders(user, OrderStatus.OPEN);
    }

    function _filter_orders(address user, OrderStatus status) internal view returns (Order[] memory) {
        uint orderCount = 0;

        Order[] memory allOrders;

        if(user != address(0)) {
            allOrders = creatorToOrder[user];
        } else {
            allOrders = orderList;
        }

        // Count open orders in a single pass
        for (uint i = 0; i < allOrders.length; i++) {
            if (allOrders[i].status == status) {
                orderCount++;
            }
        }

        // Create an array for open orders
        Order[] memory openOrders = new Order[](orderCount);
        uint index = 0;

        // Populate the open orders array in a single pass
        for (uint i = 0; i < allOrders.length; i++) {
            if (allOrders[i].status == status) {
                openOrders[index++] = allOrders[i];
            }
        }

        return openOrders;
    }
}