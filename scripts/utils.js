async function getFeeData() {
  const feeData = await ethers.provider.getFeeData();
  feeData.maxPriorityFeePerGas = 1e8;
  if (feeData.maxFeePerGas > 10e9) {
    feeData.maxFeePerGas = 10e9;
  }
  return feeData;
}

async function getSigner() {
  const signer = await ethers.provider.getSigner();
  return signer;
}

async function type2Transaction(callFunction, ...params) {
  const signer = await getSigner();
  const feeData = await getFeeData();
  const unsignedTx = await callFunction.request(...params);
  const tx = await signer.sendTransaction({
    from: unsignedTx.from,
    to: unsignedTx.to,
    data: unsignedTx.data,
    gasPrice: 1e8,
    gasLimit: 80e6
  });
  await tx.wait();
  return tx;
}

module.exports = {
  type2Transaction,
};
