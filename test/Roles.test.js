const Roles = artifacts.require("Roles");
const { shouldThrow } = require('../utils');

// Traditional Truffle test
contract("Roles", accounts => {

    let roles;

    beforeEach(async () => {
        roles = await Roles.deployed();
    });

    // количество энергии которое потребляется зависит от структуры передавемых данных, а они могут быть бесконечным
    describe('DoS tests', async () => {
        const bytesDoSFactory = () => `0x${"f".repeat(100000)}`;

        it('should test addSubject DoS', async () => {
            await roles.addRole('test');
            const res = await shouldThrow(
                roles.addSubject('test', accounts[0], 0, bytesDoSFactory())
            );
            assert.isOk(res);
        });
        it("should test setData DoS", async () => {
            await roles.addRole('test');
            await roles.addSubject('test', accounts[0], 0, '0x0');
            const res = await shouldThrow(
                roles.setData('test', accounts[0], bytesDoSFactory())
            );
            assert.isOk(res);
        });
    });
});