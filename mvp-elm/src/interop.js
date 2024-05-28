import { initDB, getAll, upload } from "./js/store.js";
// This is called BEFORE your Elm app starts up
//
// The value returned here will be passed as flags
// into your `Shared.init` function.
export const flags = ({ env }) => {
  return {
    message: "Hello, from JavaScript flags!",
  };
};

// This is called AFTER your Elm app starts up
//
// Here you can work with `app.ports` to send messages
// to your Elm application, or subscribe to incoming
// messages from Elm
export const onReady = ({ app, env }) => {
  initDB();
  if (app.ports && app.ports.outgoing) {
    app.ports.outgoing.subscribe(({ tag, data }) => {
      switch (tag) {
        case "LOGIN":
          getAccount();
          return;
        case "UPLOAD":
          upload(data);
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

  async function sync() {
    const docs = await getAll();
    console.log(docs);

    app.ports.incoming.send({
      tag: "GOT_DOCS",
      data: { docs: docs.map((x) => x.file) },
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
    console.log(accounts);

    app.ports.incoming.send({
      tag: "GOT_ACCOUNT",
      data: { accounts: accounts },
    });
  }
};
