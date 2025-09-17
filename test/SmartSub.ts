import { expect } from 'chai';
import { network } from 'hardhat';

const { ethers } = await network.connect();

const title = "Super Duper Subscription";
const duration = 30*60*60*24;
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
        it('Should create a new subscription with the correct values', async () => {
            const { smartSub, account } = await smartSubFixture();
            
            const sub = await smartSub.subs(1);

            expect(sub.title).to.equal(title);
            expect(sub.durationSeconds).to.equal(duration);
            expect(sub.priceWei).to.equal(price);
            expect(sub.owner).to.equal(account[0].address);
        });
    });

    describe('Subscription state functions', () => {
        it('should revert with error when pausing a sub that you do not own', async () => {
            const { smartSub, account } = await smartSubFixture();

            await expect(smartSub.connect(account[1]).pauseSub(1))
                .to.be.revertedWithCustomError(smartSub, 'NotOwner')
                .withArgs(account[1].address);
        });

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

        it('should set a new subscription price', async () => {
            const { smartSub } = await smartSubFixture();

            await smartSub.setSubPrice(1, ethers.parseEther("0.6"));

            expect((await smartSub.subs(1)).priceWei).to.equal(ethers.parseEther("0.6"));
        });

        it('should set a new subscription duration', async () => {
            const { smartSub } = await smartSubFixture();

            await smartSub.setSubDuration(1, duration * 2);

            expect((await smartSub.subs(1)).durationSeconds).to.equal(duration * 2);
        });
    });
})

describe('Subscribe functionality', () => {

    describe('Subscription time functions', () => {
        it('Should revert with reason when calling buySub on paused sub', async () => {
            const {smartSub} = await smartSubFixture();

            await smartSub.pauseSub(1);

            await expect(smartSub.buySub(1)).to.be
                .revertedWithCustomError(smartSub, 'SubscriptionPaused');
        });

        it('Should revert with reason when calling buySub with insufficient msg.value', async () => {
            const {smartSub} = await smartSubFixture();

            await expect(smartSub.buySub(1)).to.be
                .revertedWithCustomError(smartSub, 'IncorrectValue');
        });

        it('Should add time to userSub[msg.sender] when sufficient msg.value', async () => {
            const {smartSub, account} = await smartSubFixture();

            await smartSub.connect(account[1]).buySub(1, {value: price});

            expect(await smartSub.isUserSubscribed(account[1].address, 1)).to.be.true;
        });

        it('Should not gift time to userSub[address] when insufficient msg.value', async () => {
            const {smartSub, account} = await smartSubFixture();

            await expect(smartSub.giftSub(account[1].address, 1)).to.be.revertedWithCustomError(smartSub, 'IncorrectValue');
        });

        it('Should gift time to userSub[address] when sufficient msg.value', async () => {
            const {smartSub, account} = await smartSubFixture();

            await smartSub.giftSub(account[1].address, 1, {value: price});

            expect(await smartSub.isUserSubscribed(account[1].address, 1)).to.be.true;
        });

        it('should only retrieve active subscriptions for an address where 1 subscription has expired', async () => {
            const {smartSub, account} = await smartSubFixture();

            await smartSub.createSub("A", duration , price, activate);
            await smartSub.createSub("B", duration , price, activate);
            await smartSub.createSub("C", 1 , price, activate);

            await smartSub.connect(account[1]).buySub(1, {value: price});
            await smartSub.connect(account[1]).buySub(2, {value: price});
            await smartSub.connect(account[1]).buySub(3, {value: price});
            await smartSub.connect(account[1]).buySub(4, {value: price});

            await ethers.provider.send("evm_increaseTime", [1000]);
            await ethers.provider.send("evm_mine", []);

            const [titles, ids, expirations] = await smartSub.getActiveSubs(account[1].address);


            expect(titles.length).to.equal(3);
            expect(ids.length).to.equal(3);
            expect(expirations.length).to.equal(3);
        });
    });

    describe('Subscription payment functions', () => {
        it('should increase creators balance sheet when sub is bought', async () => {
            const {smartSub, account} = await smartSubFixture();
            const amount = ethers.parseEther("0.5");
            const creator = account[0];
            const buyer = account[1];

            const beforeBalance = await smartSub.viewBalance();
            await smartSub.connect(buyer).buySub(1, {value: amount});
            const afterBalance = await smartSub.connect(creator).viewBalance();

            expect(afterBalance).to.be.greaterThan(beforeBalance);
        });

        it('should increase wallet balance after withdrawal', async () => {
            const {smartSub, account} = await smartSubFixture();
            
            const amount = ethers.parseEther("0.5");
            const creator = account[0];
            const buyer = account[1];

            const beforeBalance = await ethers.provider.getBalance(creator.address);
            
            await smartSub.connect(buyer).buySub(1, {value: amount});
            await smartSub.connect(creator).withdrawBalance();

            const afterBalance = await ethers.provider.getBalance(creator.address);

            expect(afterBalance).to.be.greaterThan(beforeBalance);
        });

        it('should revert with reason if no balance', async () => {
            const {smartSub, account} = await smartSubFixture();

            await expect(smartSub.connect(account[0]).withdrawBalance())
                .to.be.revertedWithCustomError(smartSub, 'EmptyBalance');
        });
    });

    describe('Fallback and Receive', () => {
        it('Should revert with FunctionNotFound', async () => {
            const {smartSub, account} = await smartSubFixture();

            await expect(account[0].sendTransaction({
                to: smartSub.getAddress(), data: "0x1234"
            })).to.be.revertedWithCustomError(smartSub, 'FunctionNotFound');
        });

        it('Should revert with PaymentDataMissing', async () => {
            const {smartSub, account} = await smartSubFixture();

            await expect(account[0].sendTransaction({
                to: smartSub.getAddress(), 
                value: ethers.parseEther("0.5")
            })).to.be.revertedWithCustomError(smartSub, 'PaymentDataMissing');
        });
    });
    
    
});

