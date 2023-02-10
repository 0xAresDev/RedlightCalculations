import pytest
#from brownie import accounts
from scripts.interact import add_buy_order, get_buy_orders, add_sell_order, get_sell_orders, close_buy_order, close_sell_order, get_buy_order_length, get_sell_order_length
from scripts.helpers import get_account
from scripts.deployment import deploy_OrderBook



def test_add_buy_order():
    deploy_OrderBook()
    add_buy_order(get_account(0), 20000, 1)
    order = get_buy_orders(0)
    assert order[0] == get_account(0).address
    assert order[1] == 20000
    assert order[2] == 1

def test_add_sell_order():
    deploy_OrderBook()
    add_sell_order(get_account(0), 20000, 1)
    order = get_sell_orders(0)
    assert order[0] == get_account(0).address
    assert order[1] == 20000
    assert order[2] == 1

def test_close_buy_order():
    deploy_OrderBook()
    add_buy_order(get_account(0), 20000, 1)
    close_buy_order(get_account(0).address)
    length = get_buy_order_length()
    assert length == 0

def test_close_sell_order():
    deploy_OrderBook()
    add_sell_order(get_account(0), 20000, 1)
    close_sell_order(get_account(0).address)
    length = get_sell_order_length()
    assert length == 0