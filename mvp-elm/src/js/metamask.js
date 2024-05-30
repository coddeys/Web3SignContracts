
export async function requestAccounts() {
  const accounts = await window.ethereum
    .request({ method: "eth_requestAccounts" })
    .catch((err) => {
      if (err.code === 4001) {
        // EIP-1193 userRejectedRequest error
        // If this happens, the user rejected the connection request.
        console.log("Please connect to MetaMask.");
      } else {
        console.error(err);
      }
    });
  return accounts;
}

export async function getAccounts() {
  let accounts = await ethereum.request({ method: 'eth_accounts' });
  return accounts;
}

