// TODO: тесты на reentrancy, тесты на работоспобность
pragma solidity >=0.4.0 <0.7.0;

library RolesLib {

    struct Role {
        uint count;
        mapping (uint => address) numToAcc; // from 1 to Inf
        mapping (address => uint) accToNum;
        mapping (address => Subject) subjects;
    }

    struct Store {
        // всего может существовать 255 ролей при добавлении новой роли, будет оверфлоу
        uint8 count;
        mapping (uint8 => string) roleNames; // from 1 to Inf
        mapping (string => Role) roles;
    }

    struct Subject {
        // не имеет смысла на этом уровне абстракции, кроме метода haveRollAndAccess, но нигде не используется
        uint8 accessLevel;
        // динамический массив, неограничен по размерам, потому можно сделать DoS
        bytes data;
    }

    function _addRole(Store storage s, string memory name) internal {
        s.count += 1;
        s.roleNames[s.count] = name;
    }

    function _addSubject(Store storage s, string memory r, address account, uint8 accessLevel, bytes memory data) internal {
        require(!exist(s, r, account), "Roles: account already has role");

        s.roles[r].count += 1;

        s.roles[r].subjects[account] = Subject(accessLevel, data);
        s.roles[r].numToAcc[s.roles[r].count] = account;
        s.roles[r].accToNum[account] = s.roles[r].count;
    }

    function _removeSubject(Store storage s, string memory r, address account) internal {
        require(exist(s, r, account), "Roles: account do not have a role");

        s.roles[r].numToAcc[s.roles[r].accToNum[account]] = s.roles[r].numToAcc[s.roles[r].count];
        s.roles[r].accToNum[s.roles[r].numToAcc[s.roles[r].count]] = s.roles[r].accToNum[account];
        s.roles[r].accToNum[account] = 0;

        s.roles[r].count -= 1;
    }

    function _updateAccessLevel(Store storage s, string memory r, address account, uint8 accessLevel) internal {
        require(exist(s, r, account), "Roles: can not update account: not exist");

        s.roles[r].subjects[account].accessLevel = accessLevel;
    }

    function exist(Store storage s, string memory r, address account) public view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");

        return s.roles[r].accToNum[account] > 0;
    }

    // метод лучше сделать external потому что он нигде внутри библиотеки не используется
    function haveRoleAndAccess(Store storage s, string memory r, address account, uint8 requiredLevel) public view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");

        return exist(s, r, account)
        && (s.roles[r].accToNum[account] > 0) // дублирует верхний вызов метода
        && (s.roles[r].subjects[account].accessLevel >= requiredLevel);
    }

    function _setData(Store storage s, string memory r, address account, bytes memory data) internal {
        require(exist(s, r, account), "Roles: account does not have a role");
        s.roles[r].subjects[account].data = data;
        // тут не хватает haveRoleAndAccess
    }

}

contract Roles {
    RolesLib.Store private _store;

    function addRole(string calldata name) external {
        RolesLib._addRole(_store, name);
    }

    function addSubject(string calldata roleName, address account, uint8 accessLevel, bytes calldata data) external {
        RolesLib._addSubject(_store, roleName, account, accessLevel, data);
    }

    function removeSubject(string calldata roleName, address account) external {
        RolesLib._removeSubject(_store, roleName, account);
    }

    function updateAccessLevel(string calldata roleName, address account, uint8 accessLevel) external {
        RolesLib._updateAccessLevel(_store, roleName, account, accessLevel);
    }

    function setData(string calldata roleName, address account, bytes calldata data) external {
        RolesLib._setData(_store, roleName, account, data);
    }

    function checkStoreRoleNames(uint8 num) external view returns(string memory) {
        return _store.roleNames[num];
    }

    function getStoreCount() external view returns (uint) {
        return _store.count;
    }

    function getRoleCount(string calldata role) external view returns (uint) {
        return _store.roles[role].count;
    }

    function getRoleNumToAcc(string calldata role, uint n) external view returns (address) {
        return _store.roles[role].numToAcc[n];
    }

    function getRoleAccToNum(string calldata role, address acc) external view returns (uint) {
        return _store.roles[role].accToNum[acc];
    }

    function getRoleSubjects(string calldata role, address acc) external view returns (uint8 accessLevel, bytes memory data) {
        RolesLib.Subject memory subject = _store.roles[role].subjects[acc];
        return (subject.accessLevel, subject.data);
    }
}