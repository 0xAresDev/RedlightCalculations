from brownie import OrderBook, network, accounts, config
from .helpers import get_account


def deploy_OrderBook():
    account = get_account()
    order_book = OrderBook.deploy(account.address, {"from":account})
    return order_book

def main():
    deploy_OrderBook()
