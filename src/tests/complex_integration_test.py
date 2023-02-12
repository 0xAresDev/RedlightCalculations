import pytest
#from brownie import accounts
from scripts.interact import add_buy_order, get_buy_orders, add_sell_order, get_sell_orders, close_buy_order, close_sell_order, get_buy_order_length, get_sell_order_length
from scripts.helpers import get_account
from scripts.deployment import deploy_OrderBook
import random
#import time
# the goal would be to have random test scenario but this would require me to rebuild the orderbook dex in python
# you know what, I am gonna do that

def sort_func(elem):
        return elem[1]


# Note: in here the sell_orders is ordered upwards and not downwards 0;10;20, in the contracts its 20;10;0
class OrderBookPython():

    buy_orders = []
    sell_orders = []


    def add_buy(self, address, price, amount):
        
        fullfill_sell = []

        start_am = amount
        to_del = []
        c_max = 0
        if len(self.buy_orders) > 0:
            c_max = self.buy_orders[-1][1]
        self.buy_orders.append([address, price, amount])
        self.buy_orders.sort(key=sort_func)
        
        if price >  c_max:
            
            for i, e in enumerate(self.sell_orders):
                amount = self.buy_orders[-1][2]
                if price >= e[1]:
                    if amount >= e[2]:
                        fullfill_sell.append(e)
                        to_del.append(i)
                        self.buy_orders[-1][2] -= e[2]
                        if amount==0:
                            break
                    else:
                        fullfill_sell.append([e[0], e[1], amount])
                        #to_del.append(i)
                        self.sell_orders[i][2] -= amount
                        self.buy_orders[-1][2] = 0
                        break
            

                else:
                    break
            

            self.sell_orders = [e for i, e in enumerate(self.sell_orders) if i not in to_del]

            actual_amount = sum([e[2] for e in fullfill_sell])
            price_dif = sum([(price-e[1])*e[2] for e in fullfill_sell])

            # BTC payments, price dif and stablecoin payments to sellers
            if self.buy_orders[-1][2] == 0:
                self.buy_orders.pop(-1)

            return [(address, actual_amount), (address, price_dif), [(e[0], e[1]*e[2]) for e in fullfill_sell]]
        return False

        


    def add_sell(self, address, price, amount):
        
        fullfill_buy = []

        start_am = amount
        to_del = []
        c_min = 1000000
        if len(self.sell_orders) > 0:
            c_min = self.sell_orders[0][1]

        self.sell_orders.append([address, price, amount])
        self.sell_orders.sort(key=sort_func)
        
        if price <  c_min:
            
            for i in range(len(self.buy_orders)-1, 0,-1):
                e = self.buy_orders[i]
                amount = self.sell_orders[0][2]
                if price <= e[1]:
                    if amount >= e[2]:
                        fullfill_buy.append(e)
                        to_del.append(i)
                        self.sell_orders[0][2] -= e[2]
                        if amount==0:
                            break
                    else:
                        fullfill_buy.append([e[0], e[1], amount])
                        #to_del.append(i)
                        self.buy_orders[i][2] -= amount
                        self.sell_orders[0][2] = 0
                        break
            

                else:
                    break
            

            self.buy_orders = [e for i, e in enumerate(self.buy_orders) if i not in to_del]

            actual_amount = sum([e[2] for e in fullfill_buy])
            #price_dif = sum([(price-e[1])*e[2] for e in fullfill_sell])

            if self.sell_orders[0][2] == 0:
                self.sell_orders.pop(0)
            
            # DAI payment to seller, price dif to buyers and BTC to buyer
            return [(address, actual_amount*price), [(e[0], (e[1]-price)*e[2]) for e in fullfill_buy], [(e[0], e[2]) for e in fullfill_buy]]
        return False

    def close_buy(self, address):
        pass

    def close_sell(self, address):
        pass




def test_scenario_1():
    #orderbook = deploy_OrderBook()
    """order_py = OrderBookPython()
    order_py.add_buy(0, 2, 1)
    order_py.add_buy(0, 4, 1)
    order_py.add_buy(0, 1, 1)
    assert order_py.buy_orders[2][1] == 4
    assert order_py.buy_orders[0][1] == 1"""
    #time.sleep(1)

    #order_py = OrderBookPython()
    #order_py.add_buy(0,2000,1)
    #assert order_py.buy_orders[0][1] == 2000

    order_py = OrderBookPython()
    deploy_OrderBook()

    for i in range(10):
        if random.randrange(0,100)>50:
            wallet = random.randint(0,7)
            price = random.randrange(1000,10000)
            amount = random.randrange(0,10)
            x = order_py.add_sell(wallet,price, amount)
            tx = add_sell_order(get_account(wallet), price, amount)
            #print(tx.events)
            if "SendDAI" in tx.keys():
                assert tx["SendDAI"][-1]["receiver"] == get_account(x[0][0])
                assert tx["SendDAI"][-1]["amount"] == x[0][1]

                #assert tx["SendBTC"][0]["receiver"] == get_account(x[0][0])
                #assert tx["SendBTC"][0]["amount"] == x[0][1]
            
            
        else:
            wallet = random.randint(0,7)
            price = random.randrange(1000,10000)
            amount = random.randrange(0,10)
            x = order_py.add_buy(wallet,price,amount)
            tx = add_buy_order(get_account(wallet), price, amount)
            if "SendDAI" in tx.keys():
                assert tx["SendDAI"][0]["receiver"] == get_account(x[1][0])
                assert tx["SendDAI"][0]["amount"] == x[1][1]

                assert tx["SendBTC"][0]["receiver"] == get_account(x[0][0])
                assert tx["SendBTC"][0]["amount"] == x[0][1]




    #order_py.add_sell(0,2000,1)
    #order_py.add_buy(0,2000,1)
    #print(x)
    

    #assert len(order_py.sell_orders) == 0

