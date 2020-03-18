
const shouldThrow = async (fn) => {
    try {
        await fn;
        return false;
    } catch(err) {
        return true;
    }
};

module.exports = { shouldThrow };