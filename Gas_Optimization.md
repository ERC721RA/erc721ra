## Basic Gas Optimization

**1. Use memory where possible instead of storage**

**2. Variable Packing in Struct**

```
struct SomeData {
    uint32 balance;
    uint64 amount;
    uint256 price;
}
```

Instead of

```
struct SomeData {
    uint32 balance;
    uint256 price;
    uint64 amount;
}
```

Uint32 and uint64 can be packed together

**3. Use constant and immutable for constant values to save gas**

**4. External function uses less gas than public function**

**5. Use Revert instead of Require where possible**

example:

```
error MintZeroAmount();
if (amount == 0) revert SomeError();
```

Instead of

```
require(amount != 0, "Some Error!");
```

Because strings use more gas

**6. Each variable assignment cost more gas**

## Other Gas Saving tips:

- https://dev.to/javier123454321/solidity-gas-optimization-pt1-4271

- https://moralis.io/gas-optimizations-in-solidity-top-tips/

- https://github.com/iskdrews/awesome-solidity-gas-optimization
