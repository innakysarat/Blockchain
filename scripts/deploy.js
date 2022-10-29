require('hardhat')
 
async function main() {
   const [deployer] = await ethers.getSigners();
   console.log(`Address deploying the contract --> ${deployer.address}`);
   const PaperRockScissors = await ethers.getContractFactory("RockPaperScissors");
   const contract = await PaperRockScissors.deploy(1, 1, 2);  
   console.log(`Contract Address --> ${contract.address}`);
 
 
}
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
