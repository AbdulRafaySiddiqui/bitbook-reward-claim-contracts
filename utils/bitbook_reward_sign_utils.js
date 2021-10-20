const ethers = require('ethers')
const ABI = require('../abi/bitbook_claim_reward_abi.json')
const dotenv = require('dotenv');
dotenv.config();


const RPC_URL = 'https://bsc-dataseed.binance.org/'

const NAME = 'BITBOOK_REWARD_CLAIM'
const VERSION = '1'
const CHAIN_ID = 56;
const REWARD_CLAIM_ADDRESS = ''
const DEADLINE = 3600;

const provider = ethers.getDefaultProvider(RPC_URL);
const rewardSignContract = new ethers.Contract(REWARD_CLAIM_ADDRESS, ABI, provider)

const signReward = async (account, amount) => {
    const nonce = await rewardSignContract.nonces(account);
    const deadline = Math.ceil(Date.now() / 1000) + DEADLINE;

    const domain = {
        name: NAME,
        version: VERSION,
        chainId: CHAIN_ID,
        verifyingContract: REWARD_CLAIM_ADDRESS,
    }
    const types = {
        ClaimRewards: [
            { name: 'user', type: 'address' },
            { name: 'amount', type: 'uint256' },
            { name: 'nonce', type: 'uint256' },
            { name: 'deadline', type: 'uint256' },
        ]
    }
    const message = {
        user: account,
        amount: amount,
        nonce: nonce.toString(),
        deadline: deadline,
    }

    const wallet = new ethers.Wallet(process.env.REWARD_SIGNER, provider);

    const signature = await wallet._signTypedData(domain, types, message);

    return {
        account,
        amount,
        nonce,
        deadline,
        signature: signature,
    }
}

const shouldResetRewards = async (account, currentNounce) => {
    const nextNounce = await rewardSignContract.nonces(account);
    return nextNounce.toNumber() > currentNounce;
}