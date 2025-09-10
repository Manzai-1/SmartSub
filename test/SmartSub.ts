import { expect } from 'chai';
import { network } from 'hardhat';

const { ethers } = await network.connect();

async function smartSubFixture() {
    const SmartSub = await ethers.getContractFactory('SmartSub');
    const smartSub = await SmartSub.deploy();

    return { smartSub };
}

describe('Create Subscription', () => {
    it('Should create a new subscription witch gets id = 1 and exist = true', async () => {
        const { smartSub } = await smartSubFixture();

        await smartSub.createSub("Test",30,5000, true);
        const sub = await smartSub.subs(1);

        expect(sub.exists).to.equal(true);
    });
});

describe('Change Subscription State', () => {
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
