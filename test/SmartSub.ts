import { expect } from 'chai';
import { network } from 'hardhat';
import { parseEther } from "ethers";

const { ethers } = await network.connect();

const title = "Super Duper Subscription";
const duration = 30;
const price = ethers.parseEther("0.5");
const activate = true;

async function smartSubFixture() {
    const account = await ethers.getSigners();
    const SmartSub = await ethers.getContractFactory('SmartSub');
    const smartSub = await SmartSub.deploy();

    await smartSub.createSub(title, duration , price, activate);

    return { smartSub, account };
}

describe('Subscription Products', () => {

    describe('Create Subscription', () => {
        it('Should create a new subscription witch gets id = 1 and exist = true', async () => {
            const { smartSub } = await smartSubFixture();
            
            const sub = await smartSub.subs(1);

            expect(sub.exists).to.equal(true);
        });
    });

    describe('Subscription state functions', () => {
        it('should activate a sub after creating it as paused', async () => {
            const { smartSub } = await smartSubFixture();

            await smartSub.createSub(title, duration , price, false);
            await smartSub.activateSub(2);

            expect(await smartSub.isSubActive(2)).to.be.true;
        });

        it('should pause a sub after creating it as active', async () => {
            const { smartSub } = await smartSubFixture();

            await smartSub.pauseSub(1);

            expect(await smartSub.isSubActive(1)).to.be.false;
        });
    });
})

describe('Subscribe functionality', () => {

    describe('Subscription time functions', () => {
        it('Should revert with reason when calling buySub with insufficient msg.value', async () => {
            const {smartSub} = await smartSubFixture();

            await expect(smartSub.buySub(1)).to.be.revertedWith('Transaction value does not meet the price.');
        });

        it('Should add time to userSub[msg.sender] when sufficient msg.value', async () => {
            const {smartSub, account} = await smartSubFixture();

            await smartSub.buySub(1, {value: parseEther("0.5")});

            const expiresAt = await smartSub.userSubs(account[0].address, 1);
            expect(expiresAt).to.be.greaterThan(0);
        });

        it('Should not gift time to userSub[address] when insufficient msg.value', async () => {
            const {smartSub, account} = await smartSubFixture();

            await expect(smartSub.giftSub(account[1].address, 1)).to.be.revertedWith('Transaction value does not meet the price.');
        });

        it('Should gift time to userSub[address] when sufficient msg.value', async () => {
            const {smartSub, account} = await smartSubFixture();

            await smartSub.giftSub(account[1].address, 1, {value: parseEther("0.5")});

            const expiresAt = await smartSub.userSubs(account[1].address, 1);
            expect(expiresAt).to.be.greaterThan(0);
        });
    })

    describe('Subscription payment functions', () => {
        it('should increase creators balance sheet when sub is bought', async () => {
            const {smartSub, account} = await smartSubFixture();

            const beforeBalance = await smartSub.viewBalance();
            await smartSub.connect(account[1]).buySub(
                1, {value: ethers.parseEther("0.5")}
            );
            const afterBalance = await smartSub.viewBalance();

            expect(afterBalance).to.be.greaterThan(beforeBalance);
        })
    })
    
})

