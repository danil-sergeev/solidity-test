const Roles = artifacts.require("Roles");
const { shouldThrow } = require('../utils');

// Traditional Truffle test
contract("Roles", accounts => {

    let roles;
    let [acc] = accounts;

    beforeEach(async () => {
        roles = await Roles.new();
    });

    // количество энергии которое потребляется зависит от структуры передавемых данных, а они могут быть бесконечным
    describe('DoS tests', async () => {
        const bytesDoSFactory = () => `0x${"f".repeat(100000)}`;

        it('should test addSubject DoS', async () => {
            await roles.addRole('test');
            const res = await shouldThrow(
                roles.addSubject('test', acc, 0, bytesDoSFactory())
            );
            assert.isOk(res);
        });

        it("should test setData DoS", async () => {
            await roles.addRole('test');
            await roles.addSubject('test', acc, 0, '0x0');
            const res = await shouldThrow(
                roles.setData('test', acc, bytesDoSFactory())
            );
            assert.isOk(res);
        });
    });


    describe("Overflow tests", async () => {
        it('should test addRole overflow', async () => {
            for (let i = 0; i < 255; i++ ) {
                await roles.addRole(`test${i}`);
            }
            await roles.addRole('error');
            const res = await roles.checkStoreRoleNames(0);
            assert.equal(res, 'error');
            assert.notEqual(res, 'test0');
        });
    });

    describe("Unit tests", async () => {
        it("addRole unit test", async () => {
            await roles.addRole('testrole');
            const [count, role] = await Promise.all([
                roles.getStoreCount(),
                roles.checkStoreRoleNames(1)
            ]);
            assert.equal(count, 1);
            assert.equal(role, 'testrole');
        });

        it("addSubject unit test:success", async () => {
            await roles.addRole('test-role');
            await roles.addSubject('test-role', acc, 1, '0x1');

            const count = await roles.getRoleCount('test-role');

            const [accToNum, numToAcc, subject] = await Promise.all([
                roles.getRoleAccToNum('test-role', acc),
                roles.getRoleNumToAcc('test-role', count),
                roles.getRoleSubjects('test-role', acc)
            ]);

            assert.equal(count, 1);
            assert.equal(accToNum.toString(), count.toString());
            assert.equal(numToAcc, acc);
            assert.equal(subject.accessLevel, 1);
            assert.equal(subject.data, "0x01");
        });

        it("addSubject unit test:revert", async () => {
            await roles.addRole('test-role');
            await roles.addSubject('test-role', acc, 1, '0x1');

            const count = await roles.getRoleCount('test-role');

            const [accToNum, numToAcc, subject] = await Promise.all([
                roles.getRoleAccToNum('test-role', acc),
                roles.getRoleNumToAcc('test-role', count),
                roles.getRoleSubjects('test-role', acc)
            ]);

            assert.equal(count, 1);
            assert.equal(accToNum.toString(), count.toString());
            assert.equal(numToAcc, acc);
            assert.equal(subject.accessLevel, 1);
            assert.equal(subject.data, "0x01");

            const res = await shouldThrow(roles.addSubject('test-role', acc, 1, '0x1'));
            assert.isOk(res);
        });


        it("removeSubject unit test:success", async () => {
            await roles.addRole('test-role');
            await roles.addSubject('test-role', acc, 1, '0x0');

            await roles.removeSubject('test-role', acc);

            const count = await roles.getRoleCount("test-role");

            assert.equal(count, 0);
        });

        it("removeSubject unti test:revert", async () => {
            await roles.addRole('test-role');
            await roles.addSubject('test-role', acc, 1, '0x0');

            const res = await shouldThrow(roles.removeSubject('test-role', accounts[1]));
            assert.isOk(res);
        });

        it("updateSuccessLevel unit test:success", async () => {
            await roles.addRole('test-role');
            await roles.addSubject('test-role', acc, 1, '0x1');

            let subj = await roles.getRoleSubjects('test-role', acc);
            assert.equal(subj.accessLevel, 1);

            await roles.updateAccessLevel('test-role', acc, 2);

            subj = await roles.getRoleSubjects('test-role', acc);
            assert.equal(subj.accessLevel, 2);
        });
        it("updateSuccessLevel unit test:revert", async () => {
            await roles.addRole('test-role');
            await roles.addSubject('test-role', acc, 1, '0x1');

            const res = await shouldThrow(
                roles.updateAccessLevel('test-role', accounts[1], 3) // another acc, so it throws err
            );
            assert.isOk(res);
        });

        it("setData unit test:success", async () => {
            await roles.addRole('test-role');
            await roles.addSubject('test-role', acc, 1, '0x1');
            let subj = await roles.getRoleSubjects('test-role', acc);
            assert.equal(subj.data, '0x01');
            await roles.setData('test-role', acc, '0x2');
            subj = await roles.getRoleSubjects('test-role', acc);
            assert.equal(subj.data, '0x02');
        });

        it("setData unit test:revert", async () => {
            await roles.addRole('test-role');
            await roles.addSubject('test-role', acc, 1, '0x1');

            const res = await shouldThrow(
                roles.setData('test-role', accounts[1], '0x2') // another acc
            );
            assert.isOk(res);
        });
    });
});