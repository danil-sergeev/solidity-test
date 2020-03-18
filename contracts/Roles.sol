pragma solidity >=0.4.0 <0.7.0;

library RolesLib {

    struct Role {
        uint count;
        mapping (uint => address) numToAcc; // from 1 to Inf
        mapping (address => uint) accToNum;
        mapping (address => Subject) subjects;
    }

    struct Store {
        // всего может существовать 256 ролей при добавлении новой роли, будет оверфлоу
        uint8 count;
        mapping (uint8 => string) roleNames; // from 1 to Inf
        mapping (string => Role) roles;
    }

    struct Subject {
        uint8 accessLevel;
        bytes data;
    }

    function _addRole(Store storage s, string memory name) internal {
        s.count += 1;
        s.roleNames[s.count] = name;
    }

    function _addSubject(Store storage s, string memory r, address account, uint8 accessLevel, bytes memory data) internal {
        // TODO: uncomment! require(!exist(s, r, account), "Roles: account already has role");

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

    function haveRoleAndAccess(Store storage s, string memory r, address account, uint8 requiredLevel) public view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");

        return exist(s, r, account)
        && (s.roles[r].accToNum[account] > 0)
        && (s.roles[r].subjects[account].accessLevel >= requiredLevel);
    }

    function _setData(Store storage s, string memory r, address account, bytes memory data) internal {
        require(exist(s, r, account), "Roles: account does not have a role");

        s.roles[r].subjects[account].data = data;
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
}