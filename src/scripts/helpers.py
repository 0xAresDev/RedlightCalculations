from brownie import accounts, network, config


LOCAL_BLOCKCHAIN_ENVIRONMENTS = ["ganache-dev"]


def get_account():
    if(network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS):
        return accounts[0]
    else:
        return accounts.add(config["wallets"]["from_key"])