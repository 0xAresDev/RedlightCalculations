from brownie import OrderBook, OrderBookDebug, network, accounts, config
from .helpers import get_account


def add_buy_order(buyer, max_price, amount):
    account = get_account(0)
    order_book = OrderBook[-1]
    tx = order_book.addBuyOrder(buyer, max_price, amount, {"from":account, "gas_limit":1000000, "allow_revert":True})
    tx.wait(1)
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

def main():
    add_buy_order_debug(get_account(1), 15000, 1)
    add_sell_order_debug(get_account(2), 12000, 10)
    add_buy_order_debug(get_account(3), 10000, 20)
    add_sell_order_debug(get_account(4), 9000, 5)