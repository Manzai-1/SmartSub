import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("SmartSubModule", (m) => {
  const smartSub = m.contract("SmartSub"); // contract name must match your Solidity file
  return { smartSub };
});