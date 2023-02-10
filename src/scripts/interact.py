from brownie import OrderBook, OrderBookDebug, network, accounts, config
from .helpers import get_account
import random


def add_buy_order(buyer, max_price, amount):
    account = get_account(0)
    order_book = OrderBook[-1]
    tx = order_book.addBuyOrder(buyer, max_price, amount, {"from":account, "gas_limit":1000000, "allow_revert":True})
    tx.wait(1)
    print(tx.events)
    return True

def add_sell_order(seller, min_price, amount):
    account = get_account(0)
    order_book = OrderBook[-1]
    tx = order_book.addSellOrder(seller, min_price, amount, {"from":account, "gas_limit":1000000, "allow_revert":True})
    tx.wait(1)
    print(tx.events)
    return True

def add_buy_order_debug(buyer, max_price, amount):
    account = get_account(0)
    order_book = OrderBookDebug[-1]
    tx = order_book.addBuyOrder(buyer, max_price, amount, {"from":account, "gas_limit":5000000, "allow_revert":True})
    tx.wait(1)
    print(tx.events)
    return True

def add_sell_order_debug(seller, min_price, amount):
    account = get_account(0)
    order_book = OrderBookDebug[-1]
    tx = order_book.addSellOrder(seller, min_price, amount, {"from":account, "gas_limit":5000000, "allow_revert":True})
    tx.wait(1)
    print(tx.events)
    return True

def close_buy_order(buyer):
    account = get_account(0)
    order_book = OrderBook[-1]
    tx = order_book.closeBuyOrder(buyer, {"from":account, "gas_limit":5000000, "allow_revert":True})
    tx.wait(1)
    print(tx.events)
    return True

def close_sell_order(seller):
    account = get_account(0)
    order_book = OrderBook[-1]
    tx = order_book.closeSellOrder(seller, {"from":account, "gas_limit":5000000, "allow_revert":True})
    tx.wait(1)
    print(tx.events)
    return True

def get_buy_orders(index):
    order_book = OrderBook[-1]
    order = order_book.buyOrders(index)
    return order

def get_sell_orders(index):
    order_book = OrderBook[-1]
    order = order_book.sellOrders(index)
    return order

def get_buy_order_length():
    order_book = OrderBook[-1]
    length = order_book.getCountBuyOrder()
    return length

def get_sell_order_length():
    order_book = OrderBook[-1]
    length = order_book.getCountSellOrder()
    return length


def main():
    """for i in range(20):
        if random.randint(0, 100) > 50:
            add_buy_order(get_account(random.randint(0,9)), random.randint(1000,25000), random.randint(1,50))
        else:
            add_sell_order(get_account(random.randint(0,9)), random.randint(1000,25000), random.randint(1,50))
    
    
    close_buy_order(get_account(1))
    close_buy_order(get_account(3))
    close_sell_order(get_account(5))
    close_sell_order(get_account(8))"""
    add_buy_order(get_account(random.randint(0,9)), random.randint(1000,25000), random.randint(1,50))
    print(get_buy_orders(0))
    #add_buy_order(get_account(1), 15000, 1)
    #add_sell_order(get_account(2), 12000, 10)
    #add_buy_order(get_account(3), 10000, 20)
    #add_sell_order(get_account(4), 9000, 5)