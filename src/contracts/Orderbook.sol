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

    BuyOrder[] public buyOrders;
    BuyOrder[] _buyOrders;
    SellOrder[] public sellOrders;
    SellOrder[] _sellOrders;

    BuyOrder[] public fullfilledBuy;
    SellOrder[] public fullfilledSell;

    event SendBTC(address receiver, uint256 amount);
    event SendDAI(address receiver, uint256 amount);

    function getBuyIndex(uint256 price) internal view returns(uint256 index){
        uint i = 0;
        while(i<buyOrders.length){
            if(price<=buyOrders[i].maxPrice){
                return(i);
            }
            i++;
        }
        return(buyOrders.length);
    }

    function getSellIndex(uint256 price) internal view returns(uint256 index){
        uint i = 0;
        while(i<sellOrders.length){
            if(price>=sellOrders[i].minPrice){
                return(i);
            }
            i++;
        }
        return(sellOrders.length);
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

    function createNewSellArray(address _seller, uint256 _minPrice, uint256 _amount, uint256 index) internal{
        for(uint i=0;i<index;i++){
            _sellOrders.push(sellOrders[i]);
        }
        _sellOrders.push(SellOrder(_seller,_minPrice,_amount));
        for(uint i=index;i<sellOrders.length;i++){
            _sellOrders.push(sellOrders[i]);
        }

        sellOrders = _sellOrders;
        delete _sellOrders;

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
        if(sellOrders.length>0){
            uint i = sellOrders.length-1;
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
                if(i==0){break;}
                i--;

            }
            if(buyOrders[buyOrders.length-1].amount==0){
                removeBuyOrder(buyOrders.length-1);
            }
        }
    }


    function checkAndFullfillSell() internal{
        SellOrder memory current = sellOrders[sellOrders.length-1];
        //uint startingAmount = current.amount;
        if(buyOrders.length > 0){
            uint i = buyOrders.length-1;
            while(i>=0 && sellOrders[sellOrders.length-1].amount!=0){
                if(buyOrders[i].maxPrice >= current.minPrice){
                    if(buyOrders[i].amount <= current.amount){
                        sellOrders[sellOrders.length-1].amount -= buyOrders[i].amount;
                        current = sellOrders[sellOrders.length-1];
                        fullfilledBuy.push(buyOrders[i]);
                        delete buyOrders[i];
                        buyOrders.pop();
                    }else{
                        BuyOrder memory tempBuy = BuyOrder(buyOrders[i].buyer, buyOrders[i].maxPrice, current.amount);
                        buyOrders[i].amount -= current.amount;
                        sellOrders[sellOrders.length-1].amount = 0;
                        current = sellOrders[sellOrders.length-1];
                        fullfilledBuy.push(tempBuy);
                        delete tempBuy;
                    }
                }
                if(i==0){break;}
                i--;

            }
            if(sellOrders[sellOrders.length-1].amount==0){
                removeSellOrder(sellOrders.length-1);
            }
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

    function payOutBuy(uint256 priceDif, uint256 amount, address _buyer) internal{
        
        //payout priceDif to buyer
        sendDAI(_buyer, priceDif);
        // payout DAI to sellers and Bitcoin to buyer

        // DAI from fullFilledSell
        for(uint i = 0; i<fullfilledSell.length; i++){

            sendDAI(fullfilledSell[i].seller, fullfilledSell[i].minPrice*fullfilledSell[i].amount);

        }
        // BTC amount from amount
        sendBTC(_buyer, amount);
    }

    function sendDAI(address receiver, uint256 amount) internal{
        emit SendDAI(receiver, amount);
    }

    function sendBTC(address receiver, uint256 amount) internal{
        emit SendBTC(receiver, amount);
    }
    

    function payOutSell(address _seller, uint _minPrice) internal{
        // pay out BTC to buyer
        // pay out DAI to seller
        // pay out price difference to buyer
        uint amount = 0;
        //uint 
        for(uint i = 0; i<fullfilledBuy.length; i++){
            amount += fullfilledBuy[i].amount;
            // price dif
            sendDAI(fullfilledBuy[i].buyer, (fullfilledBuy[i].maxPrice-_minPrice)*fullfilledBuy[i].amount);
            //BTC
            sendBTC(fullfilledBuy[i].buyer, fullfilledBuy[i].amount);
        }
        // sell amount
        sendDAI(_seller, amount*_minPrice);
    }

    function addBuyOrder(address _buyer, uint256 _maxPrice, uint256 _amount) external onlyBridge {
        uint index = getBuyIndex(_maxPrice);
        createNewBuyArray(_buyer, _maxPrice, _amount, index);
        if(index==buyOrders.length-1){
            checkAndFullfillBuys();
            (uint256 priceDifference, uint256 amount) = calculatePriceDifferenceAndAmount(_maxPrice);
            payOutBuy(priceDifference, amount, _buyer);
            // We could implement recursion here in case we want to increase the Max Price a buyer is willing to pay if he got the previous Bitcoins cheaper than his maxPrice
            delete fullfilledSell;
        }

    }

    function addSellOrder(address _seller, uint256 _minPrice, uint256 _amount) external onlyBridge {
        uint index = getSellIndex(_minPrice);
        createNewSellArray(_seller, _minPrice, _amount, index);
        if(index==sellOrders.length-1){
            checkAndFullfillSell();
            //(uint256 priceDifference, uint256 amount) = calculatePriceDifferenceAndAmount(_minPrice);
            payOutSell(_seller, _minPrice);
            // We could implement recursion here in case we want to increase the Max Price a buyer is willing to pay if he got the previous Bitcoins cheaper than his maxPrice
            delete fullfilledBuy;
        }

    }


    function closeSellOrder(address _seller) external onlyBridge {
        uint256 index = 0;
        for(uint i=0; i<sellOrders.length; i++){
            if(sellOrders[i].seller==_seller){
                index = i;
            }
        }
        
        if(index==0 && sellOrders[0].seller!=_seller){}
        else{
            // potential reentracy attack
            sendBTC(sellOrders[index].seller, sellOrders[index].amount);
            removeSellOrder(index);
        }
    }


    function closeBuyOrder(address _buyer) external onlyBridge {
        uint256 index = 0;
        for(uint i=0; i<buyOrders.length; i++){
            if(buyOrders[i].buyer==_buyer){
                index = i;
            }
        }
        if(index==0 && buyOrders[0].buyer!=_buyer){}
        else{
            // potential reentracy attack
            sendDAI(buyOrders[index].buyer, buyOrders[index].amount*buyOrders[index].maxPrice);
            removeBuyOrder(index);
        }
    
        
    }


    function getCountBuyOrder() view external returns(uint){
        return buyOrders.length;
    }

    function getCountSellOrder() view external returns(uint){
        return sellOrders.length;
    }
    



}




