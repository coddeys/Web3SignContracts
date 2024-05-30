import lighthouse from "@lighthouse-web3/sdk";
import * as LitJsSdk from "@lit-protocol/lit-node-client";

export async function encryptFile(address, doc) {
  const chain = "filecoin";

  const accessControlConditions = [
    {
      contractAddress: '',
      standardContractType: '',
      chain,
      method: '',
      parameters: [
        ':userAddress',
      ],
      returnValueTest: {
        comparator: '=',
        value: doc.address
      }
    },
    { operator: "or" },
    {
      contractAddress: '',
      standardContractType: '',
      chain,
      method: '',
      parameters: [
        ':userAddress',
      ],
      returnValueTest: {
        comparator: '=',
        value: address
      }
    },
  ];

  const authSig = await LitJsSdk.checkAndSignAuthMessage({ chain });
  const encryptedFile = await LitJsSdk.encryptFileAndZipWithMetadata({
    litNodeClient: litNodeClient,
    accessControlConditions,
    file: doc.file,
    authSig,
    chain,
  });

  return {
    encryptedFile: encryptedFile,
  };
}

export async function uploadToLighthouse(apiKey, file) {
  const zipBlob = file.zipBlob;
  const result = await lighthouse.uploadBuffer(zipBlob, apiKey);
  return result;
}

export async function getLighthouseUploads(apiKey, account) {
  const uploads = await lighthouse.getUploads(account);
  return uploads;
}

export async function getLighthouseUpload(ipfsCid) {
  const file = await getFile(ipfsCid);

  const chain = "filecoin";
  const authSig = await LitJsSdk.checkAndSignAuthMessage({ chain });

  const decryptedFile = await LitJsSdk.decryptZipFileWithMetadata({
    litNodeClient: litNodeClient,
    file: file,
    authSig
  });

  return decryptedFile;
}

async function getFile(cid) {
  let chunks = [];

  const response = await fetch(`https://gateway.lighthouse.storage/ipfs/${cid}`);
  console.log(response);
  for await (const chunk of response.body) {
    chunks.push(chunk);
  }

  return (new Blob(chunks))
}

// https://bugs.chromium.org/p/chromium/issues/detail?id=929585
// The polyfill to fix the Chrome bug.
ReadableStream.prototype[Symbol.asyncIterator] = async function* () {
  const reader = this.getReader()
  try {
    while (true) {
      const { done, value } = await reader.read()
      if (done) return
      yield value
    }
  }
  finally {
    reader.releaseLock()
  }
}
