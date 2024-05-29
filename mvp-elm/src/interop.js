import { upload, getAll,getAllKeys, del, get, set} from "./js/indexeddb.js";

// This is called BEFORE your Elm app starts up
//
// The value returned here will be passed as flags
// into your `Shared.init` function.
export const flags = ({ env }) => {
  return {
    message: "Hello, from JavaScript flags!",
  };
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
  if (app.ports && app.ports.outgoing) {
    app.ports.outgoing.subscribe(({ tag, data }) => {
      switch (tag) {
        case "LOGIN_CLICKED":
          getAccount();
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
        case "SYNC":
          sync();
          return;
        default:
          console.warn(`Unhandled outgoing port: "${tag}"`);
          return;
      }
    });
  }

  async function sign(key) {
    let doc = await get(key);
    let signedDoc = await signDoc(doc);

    await set(key, {...signedDoc, signed: true} );
    await sync();
  }

  async function signDoc(doc){
    // TODO: Sign the document
    await sleep(1000);
    return doc;
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

  async function getAccount() {
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

    app.ports.incoming.send({
      tag: "GOT_ACCOUNT",
      data: { accounts: accounts },
    });
  }
};
