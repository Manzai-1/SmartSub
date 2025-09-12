import { expect } from 'chai';
import { network } from 'hardhat';
import { parseEther } from "ethers";

const { ethers } = await network.connect();
const [owner] = await ethers.getSigners();

async function smartSubFixture() {
    const account = await ethers.getSigners();
    const SmartSub = await ethers.getContractFactory('SmartSub');
    const smartSub = await SmartSub.deploy();

    return { smartSub, account };
}

describe('Subscription Products', () => {

    describe('Create Subscription', () => {
        it('Should create a new subscription witch gets id = 1 and exist = true', async () => {
            const { smartSub } = await smartSubFixture();

            await smartSub.createSub("Test",30,5000, true);
            const sub = await smartSub.subs(1);

            expect(sub.exists).to.equal(true);
        });
    });

    describe('Subscription state functions', () => {
        it('Should find subscription to be active after creating it as paused and then activating it.', async () => {
            const { smartSub } = await smartSubFixture();

            await smartSub.createSub("Test",30,5000, false);
            await smartSub.activateSub(1);

            const sub = await smartSub.subs(1);

            expect(sub.state).to.equal(0);
        });

        it('Should find subscription to be paused after creating it as active and then pausing it.', async () => {
            const { smartSub } = await smartSubFixture();

            await smartSub.createSub("Test",30,5000, true);
            await smartSub.pauseSub(1);

            const sub = await smartSub.subs(1);

            expect(sub.state).to.equal(1);
        });
    });
})

describe('Subscribe functionality', () => {

    describe('Subscription time functions', () => {
        it('Should revert with reason when calling buySub with insufficient msg.value', async () => {
            const {smartSub} = await smartSubFixture();

            await smartSub.createSub("Test",30, parseEther("0.5"), true);
            await expect(smartSub.buySub(1)).to.be.revertedWith('Transaction value does not meet the price.');
        });

        it('Should add time to userSub[msg.sender] when sufficient msg.value', async () => {
            const {smartSub, account} = await smartSubFixture();

            await smartSub.createSub("Test",30,ethers.parseEther("0.5"), true);
            await smartSub.buySub(1, {value: parseEther("0.5")});

            const expiresAt = await smartSub.userSubs(account[0].address, 1);
            expect(expiresAt).to.be.greaterThan(0);
        });

        it('Should not gift time to userSub[address] when insufficient msg.value', async () => {
            const {smartSub, account} = await smartSubFixture();

            await smartSub.createSub("Test",30, parseEther("0.5"), true);
            await expect(smartSub.giftSub(account[1].address, 1)).to.be.revertedWith('Transaction value does not meet the price.');
        });

        it('Should gift time to userSub[address] when sufficient msg.value', async () => {
            const {smartSub, account} = await smartSubFixture();

            await smartSub.createSub("Test",30,ethers.parseEther("0.5"), true);
            await smartSub.giftSub(account[1].address, 1, {value: parseEther("0.5")});

            const expiresAt = await smartSub.userSubs(account[1].address, 1);
            expect(expiresAt).to.be.greaterThan(0);
        });
    })

    describe('Subscription payment functions', () => {
        
    })
    
})

