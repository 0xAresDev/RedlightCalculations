from brownie import accounts, network, config


LOCAL_BLOCKCHAIN_ENVIRONMENTS = ["ganache-dev"]


def get_account(index):
    if(network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS):
        return accounts[index]
    else:
        return accounts.add(config["wallets"]["from_key"])