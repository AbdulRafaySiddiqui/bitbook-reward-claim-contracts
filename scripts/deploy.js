const { ethers } = require('hardhat')
const hre = require('hardhat')

const sleep = async (s) => {
    for (let i = s; i > 0; i--) {
        process.stdout.write(`\r \\ ${i} waiting..`)
        await new Promise(resolve => setTimeout(resolve, 250));
        process.stdout.write(`\r | ${i} waiting..`)
        await new Promise(resolve => setTimeout(resolve, 250));
        process.stdout.write(`\r / ${i} waiting..`)
        await new Promise(resolve => setTimeout(resolve, 250));
        process.stdout.write(`\r - ${i} waiting..`)
        await new Promise(resolve => setTimeout(resolve, 250));
        if (i === 1) {
            process.stdout.clearLine();
            process.stdout.cursorTo(0);
            return;
        }
    }
}

const ROUTERS = {
    PANCAKE: '0x10ED43C718714eb63d5aA57B78B54704E256024E',
    PANCAKE_TESTNET: '0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3',
    UNISWAP: '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D',
    SUSHISWAP_TESTNET: '0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506',
}

const BITBOOK_ADDRESS = '0xD48474E7444727bF500a32D5AbE01943f3A59A64'
const REWARD_SIGNER = '0xC3279c74ecE9A080b3C36B4036e47FF8Aef6001b'

async function main() {
    const [deployer] = await ethers.getSigners()

    const rewardClaimContract = await ethers.getContractFactory('BitBookRewardClaim')
    const rewardClaim = await rewardClaimContract.deploy(BITBOOK_ADDRESS)
    console.log('Reward Claim: ', rewardClaim.address)

    await rewardClaim.grandRewardSignerRole(deployer.address);
    await rewardClaim.grandRewardSignerRole(REWARD_SIGNER);

    await sleep(10)

    await hre.run('verify:verify', {
        address: rewardClaim.address,
        constructorArguments: [BITBOOK_ADDRESS],
    })
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })

