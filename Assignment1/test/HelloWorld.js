/*HelloWorld.js*/
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("HelloWorld contract", async () => {

    async function deployHelloWorld() {
        const [owner,addr1] = await ethers.getSigners();

        const HelloWorldContract = await ethers.getContractFactory("HelloWorld");
        const HelloWorld = await HelloWorldContract.deploy("HelloWorld","BV",10);

        return {HelloWorld, owner,addr1};
    }

    let HelloWorldToken;
    let Owner;
    let Addr1;

    before(async () => {
        const {HelloWorld,owner,addr1} = await loadFixture(deployHelloWorld);
        HelloWorldToken = HelloWorld;
        Owner = owner;
        Addr1 = addr1;
        console.log(`Owner: ${owner.address}, Addr1: ${addr1.address}`);
 
    });

  
    it("Mint ERC20 Token", async () => {

        const ownerBalance = await HelloWorldToken.balanceOf(Owner.address);

        const name = await HelloWorldToken.name();

        const symbol = await HelloWorldToken.symbol();

        expect(await HelloWorldToken.totalSupply()).to.equal(ownerBalance);

        console.log(`name: ${name}`);
        console.log(`symbol: ${symbol}`);
        console.log(`balance: ${ownerBalance}`);


    });

    it("Transfer ERC20 Token",async() =>{
        await HelloWorldToken.transfer(Addr1.address,3);
        
        const ownerBalance = await HelloWorldToken.balanceOf(Owner.address);

        const addr1Balance = await HelloWorldToken.balanceOf(Addr1.address);

        const totalSupply = await HelloWorldToken.totalSupply();
        expect(addr1Balance).to.equal(3);

        console.log(`Total:${totalSupply},OwnerBalance:${ownerBalance},Addr1Balance:${addr1Balance}`);

    });
});