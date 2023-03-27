const { ethers } = require("hardhat");

/*deploy.js*/
async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  // const HelloWorld = await ethers.getContractFactory("HelloWorld");
  // const HelloWorldToken = await HelloWorld.deploy("HelloWorld","BV",10**15);

  // console.log("Token address:", HelloWorldToken.address);

  const hello = await ethers.getContractAt("HelloWorld", "0xe1b9d4D514174Df085Ec48b6Adab079606F12ccA");
  const bal = await hello.balanceOf(deployer.address);
  console.log(bal)

  // const tx = await hello.add()
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 