-include .env

build:; forge build
deploy-sepolia:
	forge script script/.s.sol:DeployFundMe --rpc-url $(RPC_URL_SEPOLIA) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

deploy-anvil:
	forge script script/DeployErc1155ForMinterService.s.sol:DeployErc1155ForMinterService --rpc-url $(RPC_URL_ANVIL) --private-key $(PRIVATE_KEY_ANVIL_0) --broadcast -vvvv