require('hardhat');

const main = async () => {
    const tokenName = 'Hello';
    const tokenSymbol = 'FX';

    const [deployer] = await ethers.getSigners();
    console.log(`Address deploying the contract --> ${deployer.address}`);

    const tokenFactory = await ethers.getContractFactory("Token");
    const contract = await tokenFactory.deploy(tokenName, tokenSymbol);

    console.log(`Token Contract Address --> ${contract.address}`)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });