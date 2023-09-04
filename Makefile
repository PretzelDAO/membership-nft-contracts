-include .env

build:; forge build
deploy-sepolia:
	forge script script/.s.sol:DeployFundMe --rpc-url $(RPC_URL_SEPOLIA) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

deploy-anvil:
	forge script script/DeployErc1155ForMinterService.s.sol:DeployErc1155ForMinterService --rpc-url $(RPC_URL_ANVIL) --private-key $(PRIVATE_KEY_ANVIL_0) --broadcast -vvvv

deploy-mumbai-erc721-membership-mint:
	forge script script/DeployErc721MembershipMint.s.sol:DeployErc721MembershipMint --rpc-url $(RPC_URL_MUMBAI) --private-key $(PRIVATE_KEY_MUMBAI) --broadcast --verify --etherscan-api-key $(POLYGONSCAN_API_KEY) -vvvv

deploy-mumbai-usdc-mock:
	forge create test/mocks/UsdcMock.sol:UsdcMock --rpc-url $(RPC_URL_MUMBAI) --private-key $(PRIVATE_KEY_MUMBAI) --verify --etherscan-api-key $(POLYGONSCAN_API_KEY) --nonce 3

deploy-sepolia-usdc-mock:
	forge create test/mocks/UsdcMock.sol:UsdcMock --rpc-url $(RPC_URL_SEPOLIA) --private-key $(PRIVATE_KEY) --verify --etherscan-api-key $(ETHERSCAN_API_KEY)

deploy-sepolia-erc721-membership-mint:
	forge script script/DeployErc721MembershipMint.s.sol:DeployErc721MembershipMint --rpc-url $(RPC_URL_SEPOLIA) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
