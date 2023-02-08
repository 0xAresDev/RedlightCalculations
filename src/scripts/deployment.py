from brownie import OrderBook, OrderBookDebug, network, accounts, config
from .helpers import get_account


def deploy_OrderBook():
    account = get_account(0)
    order_book = OrderBook.deploy(account.address, {"from":account})
    return order_book

def deploy_OrderBook_debug():
    account = get_account(0)
    order_book = OrderBookDebug.deploy(account.address, {"from":account})
    return order_book

def main():
    deploy_OrderBook_debug()
