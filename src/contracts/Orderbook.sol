//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


struct BuyOrder{
    address buyer;
    uint256 maxPrice;
    uint256 amount;
}

struct SellOrder{
    address seller;
    uint256 minPrice;
    uint256 amount;
}



/**
 @title Simple orderbook example
 @author 0xAres
*/

contract OrderBook{

    address bridge;

    constructor(address _bridge){
        bridge = _bridge;
    }

    modifier onlyBridge{
        require(msg.sender==bridge);
        _;
    }

    BuyOrder[] buyOrders;
    BuyOrder[] _buyOrders;
    SellOrder[] sellOrders;
    SellOrder[] _sellOrders;

    BuyOrder[] fullfilledBuy;
    SellOrder[] fullfilledSell;



    function getBuyIndex(uint256 price) internal view returns(uint256 index){
        uint i = 0;
        while(i<buyOrders.length){
            if(price<=buyOrders[i].maxPrice){
                index = i;
                return(index);
            }
            i++;
        }
        return i+1;
    }

    function createNewBuyArray(address _buyer, uint256 _maxPrice, uint256 _amount, uint256 index) internal{
        for(uint i=0;i<index;i++){
            _buyOrders.push(buyOrders[i]);
        }
        _buyOrders.push(BuyOrder(_buyer,_maxPrice,_amount));
        for(uint i=index;i<buyOrders.length;i++){
            _buyOrders.push(buyOrders[i]);
        }

        buyOrders = _buyOrders;
        delete _buyOrders;

    }

    function removeSellOrder(uint index) internal{
        if (index >= sellOrders.length) return;

        for (uint i = index; i<sellOrders.length-1; i++){
            sellOrders[i] = sellOrders[i+1];
        }
        delete sellOrders[sellOrders.length-1];
        sellOrders.pop();
        
    }

    function removeBuyOrder(uint index) internal{
        if (index >= buyOrders.length) return;

        for (uint i = index; i<buyOrders.length-1; i++){
            buyOrders[i] = buyOrders[i+1];
        }
        delete buyOrders[buyOrders.length-1];
        buyOrders.pop();
        
    }

    function checkAndFullfillBuys() internal{
        BuyOrder memory current = buyOrders[buyOrders.length-1];
        //uint startingAmount = current.amount;
        uint i = sellOrders.length;
        while(i>=0 && buyOrders[buyOrders.length-1].amount!=0){
            if(sellOrders[i].minPrice <= current.maxPrice){
                if(sellOrders[i].amount <= current.amount){
                    buyOrders[buyOrders.length-1].amount -= sellOrders[i].amount;
                    current = buyOrders[buyOrders.length-1];
                    fullfilledSell.push(sellOrders[i]);
                    delete sellOrders[i];
                    sellOrders.pop();
                }else{
                    SellOrder memory tempSell = SellOrder(sellOrders[i].seller, sellOrders[i].minPrice, current.amount);
                    sellOrders[i].amount -= current.amount;
                    buyOrders[buyOrders.length-1].amount = 0;
                    current = buyOrders[buyOrders.length-1];
                    fullfilledSell.push(tempSell);
                    delete tempSell;
                }
            }
            i--;

        }
        if(buyOrders[buyOrders.length-1].amount==0){
            removeBuyOrder(buyOrders.length-1);
        }
    }


    function calculatePriceDifferenceAndAmount(uint256 maxCost) view internal returns(uint256 priceDifference, uint256 amount){
        uint priceDif = 0;
        uint totalAmount = 0;
        for(uint i = 0; i<fullfilledSell.length;i++){
            priceDif += fullfilledSell[i].amount * (maxCost-fullfilledSell[i].minPrice);
            totalAmount += fullfilledSell[i].amount;
        }

        return(priceDif, totalAmount);
        
    }

    function payOut(uint256 priceDif, uint256 amount) internal{
        
        //payout priceDif to buyer

        // payout DAI to sellers and Bitcoin to buyer

        // DAI from fullFilledSell
        // BTC amount from amount
    }

    function addBuyOrder(address _buyer, uint256 _maxPrice, uint256 _amount) external onlyBridge {
        uint index = getBuyIndex(_maxPrice);
        createNewBuyArray(_buyer, _maxPrice, _amount, index);
        if(index==buyOrders.length-1){
            checkAndFullfillBuys();
            (uint256 priceDifference, uint256 amount) = calculatePriceDifferenceAndAmount(_maxPrice);
            payOut(priceDifference, amount);
            // We could implement recursion here in case we want to increase the Max Price a buyer is willing to pay if he got the previous Bitcoins cheaper than his maxPrice
            delete fullfilledSell;
        }

    }



}




