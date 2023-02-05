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

    function removeBuyOrder(uint index) internal{
        if (index >= buyOrders.length) return;

        for (uint i = index; i<buyOrders.length-1; i++){
            buyOrders[i] = buyOrders[i+1];
        }
        delete buyOrders[buyOrders.length-1];
        buyOrders.pop();
        
    }

    function checkAndFullfillBuys() internal{
        BuyOrder memory current = buyOrders[0];
        //uint startingAmount = current.amount;
        uint i = sellOrders.length;
        while(i>=0 && buyOrders[0].amount!=0){
            if(sellOrders[i].minPrice >= current.maxPrice){
                if(sellOrders[i].amount <= current.amount){
                    buyOrders[0].amount -= sellOrders[i].amount;
                    current = buyOrders[0];
                    fullfilledSell.push(sellOrders[i]);
                    delete sellOrders[i];
                }else{
                    SellOrder memory tempSell = SellOrder(sellOrders[i].seller, sellOrders[i].minPrice, current.amount);
                    sellOrders[i].amount -= current.amount;
                    buyOrders[0].amount = 0;
                    current = buyOrders[0];
                    fullfilledSell.push(tempSell);
                    delete tempSell;
                }
            }

        }
        if(buyOrders[0].amount==0){
            removeBuyOrder(0);
        }
    }

    function addBuyOrder(address _buyer, uint256 _maxPrice, uint256 _amount) external onlyBridge {
        uint index = getBuyIndex(_maxPrice);
        createNewBuyArray(_buyer, _maxPrice, _amount, index);
        if(index==0){
            checkAndFullfillBuys();
        }

    }



}






/// @notice Purpose struct
struct Purpose {
    address owner;
    string purpose;
    uint256 investment;
}

/**
 @title A contract to set a World Purpose
 @author Emanuele Ricci @StErMi
*/
contract WorldPurpose {
    /// @notice Track user investments
    mapping(address => uint256) private balances;

    /// @notice Track the current world purpose
    Purpose private purpose;

    /// @notice Event to track new Purpose
    event PurposeChange(address indexed owner, string purpose, uint256 investment);

    /**
     @notice Getter for the current purpose
     @return currentPurpose The current active World purpose
    */
    function getCurrentPurpose() public view returns (Purpose memory currentPurpose) {
        return purpose;
    }

    /**
     @notice Get the total amount of investment you have made. It returns both the locked and unloacked investment.
     @return balance The balance you still have in the contract
    */
    function getBalance() public view returns (uint256 balance) {
        return balances[msg.sender];
    }

    /**
     @notice Modifier to check that the prev owner of the purpose is not the same as the new proposer
    */
    modifier onlyNewUser() {
        // Check that new owner is not the previous one
        require(purpose.owner != msg.sender, "You cannot override your own purpose");
        _;
    }

    /**
     @notice Set the new world purpose
     @param _purpose The new purpose content
     @return newPurpose The new active World purpose
    */
    function setPurpose(string memory _purpose) public payable onlyNewUser returns (Purpose memory newPurpose) {
        // Check that the new owner has sent us enough funds to override the previous purpose
        require(msg.value > purpose.investment, "You need to invest more than the previous purpose owner");

        // Check if the new purpose is empty
        bytes memory purposeBytes = bytes(_purpose);
        require(purposeBytes.length > 0, "You need to set a purpose message");

        // Update the purpose with the new one
        purpose = Purpose(msg.sender, _purpose, msg.value);

        // Update the sender value
        balances[msg.sender] += msg.value;

        // Emit the PurposeChange event
        emit PurposeChange(msg.sender, _purpose, msg.value);

        // Return the new purpose
        return purpose;
    }

    /**
     @notice Withdraw the funds from the old purpose. If you have an active purpose those funds are "locked"
    */
    function withdraw() public {
        // Get the user's balance
        uint256 withdrawable = balances[msg.sender];

        // Now we need to check how much the user can withdraw
        address currentOwner = purpose.owner;
        if (currentOwner == msg.sender) {
            withdrawable -= purpose.investment;
        }

        // Check that the user has enough balance to withdraw
        require(withdrawable > 0, "You don't have enough withdrawable balance");

        // Update the balance
        balances[msg.sender] -= withdrawable;

        // Transfer the balance
        (bool sent, ) = msg.sender.call{value: withdrawable}("");
        require(sent, "Failed to send user balance back to the user");
    }
}