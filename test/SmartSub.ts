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
