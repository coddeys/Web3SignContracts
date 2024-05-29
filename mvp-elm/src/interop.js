import { upload, getAll,getAllKeys, del, get, set} from "./js/indexeddb.js";
import { requestAccounts, getAccounts } from "./js/metamask.js"
import { uploadToLighthouse } from "./js/lighthouse.js"


// This is called BEFORE your Elm app starts up
//
// The value returned here will be passed as flags
// into your `Shared.init` function.
export const flags =  ({ env }) => {
  const apiKey = env.LIGHTHOUSE_API_KEY;

  const data = { lighthouseApiKey: apiKey };
  return data;
};

function sleep (time) {
  return new Promise((resolve) => setTimeout(resolve, time));
}

// This is called AFTER your Elm app starts up
//
// Here you can work with `app.ports` to send messages
// to your Elm application, or subscribe to incoming
// messages from Elm
export const onReady = ({ app, env }) => {
  // This key should be obtained from https://lighthouse.storage
  const apiKey = env.LIGHTHOUSE_API_KEY;

  isConnected();
  if (app.ports && app.ports.outgoing) {
    app.ports.outgoing.subscribe(({ tag, data }) => {
      switch (tag) {
        case "CONNECT":
          connect();
          return;
        case "UPLOAD":
          upload(data);
          sync();
          return;
        case "DEL":
          del(data.key);
          sync();
          return;
        case "SIGN":
          sign(data.key);
          return;
        case "ENCRYPT":
          encrypt(data.key);
          return;
        case "UPLOAD_TO_IPFS":
          uploadToIPFS(apiKey, data.key);
          return;
        case "SYNC":
          sync();
          return;
        default:
          console.warn(`Unhandled outgoing port: "${tag}"`);
          return;
      }
    });
  }

  async function isConnected() {
    // It returns a wallet address if it is connected.
    const accounts = await getAccounts();

    if (accounts.length) {
      app.ports.incoming.send({
        tag: "GOT_ACCOUNT",
        data: { accounts: accounts },
      });
    }
  }

  // Initiate a connection request in response to user click
  async function connect() {
    // connect MetaMask to the dapp
    const accounts = await requestAccounts();

    app.ports.incoming.send({
      tag: "GOT_ACCOUNT",
      data: { accounts: accounts },
    });
  }

  async function sign(key) {
    let doc = await get(key);
    let sign = await signTypedData(doc);

    await set(key, {...doc, signed: sign} );
    await sync();
  }

  async function signTypedData(doc){
    // TODO: Sign the documents
    // Use eth_signTypedData_v4
    const sign = "0xecb5b466601da9c5b3f59cd583047cb8d9cef7d078a822711bd50a14ffc8c70b16b2e66de99e1eda870c6f840de51be244705767313f0d23d2a73a1ebc5255c01b"
    await sleep(1000);

    return sign;
  }

  async function encrypt(key) {
    let doc = await get(key);
    let encryptionKey = await encryptFile(doc);

    await set(key, {...doc, encryptionKey: encryptionKey} );
    await sync();
  }

  async function encryptFile(doc){
    // TODO: Encrypte the document locally
    const encryptionKey = "symmetricKey"
    await sleep(1000);

    return encryptionKey;
  }

  async function uploadToIPFS(apiKey, key) {
    let doc = await get(key);
    let lighthouseResult = await uploadToLighthouse(apiKey, doc.file);

    await set(key, {...doc, lighthouse: lighthouseResult.data } );
    await sync();
  }


  async function sync() {
    const docs = await getAll();
    const keys = await getAllKeys();
    const data =(docs.map((x,i) =>({key: (keys[i]), doc: x})));

    app.ports.incoming.send({
      tag: "GOT_DOCS",
      data: { docs: data},
    });
  }
};
