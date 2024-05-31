import { StandardFonts, rgb, degrees, PDFDocument } from 'pdf-lib'
import { getAll, getAllKeys, del, get, set } from "./js/indexeddb.js";
import { requestAccounts, getAccounts } from "./js/metamask.js"
import { encryptFile, uploadToLighthouse, getLighthouseUploads, getLighthouseUpload } from "./js/ipfs.js"
import * as LitJsSdk from "@lit-protocol/lit-node-client";
//
// The value returned here will be passed as flags
// into your `Shared.init` function.
export const flags = ({ env }) => {
  const apiKey = import.meta.env.VITE_LIGHTHOUSE_API_KEY;
  const data = { lighthouseApiKey: apiKey };
  return data;
};

function sleep(time) {
  return new Promise((resolve) => setTimeout(resolve, time));
}

async function readAsArrayBuffer(file) {
  return new Promise((res, rej) => {
    const reader = new FileReader();
    reader.readAsArrayBuffer(file);
    reader.onload = () => {
      res(reader.result);
    };
  });
}

// This is called AFTER your Elm app starts up
//
// Here you can work with `app.ports` to send messages
// to your Elm application, or subscribe to incoming
// messages from Elm
export const onReady = ({ app, env }) => {
  // This is called BEFORE your Elm app starts up
  // This key should be obtained from https://lighthouse.storage
  const apiKey = import.meta.env.VITE_LIGHTHOUSE_API_KEY;
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
        case "SET":
          setData(apiKey, data);
          return;
        case "DEL":
          del(data.key);
          sync();
          return;
        case "SIGN_AND_UPLOAD":
          signAndUpload(apiKey, data);
          return;
        case "SIGN":
          sign(data.key);
          return;
        case "DOWNLOAD_AND_DECRYPT":
          downloadAndDecrypt(data);
          return;
        case "RETRIEVE":
          retrieve(data);
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
    const client = new LitJsSdk.LitNodeClient();
    await client.connect();

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

  async function upload(data) {
    await set(data.key, { file: data.file });
  }

  async function setData(apiKey, data) {
    await updateDoc(data);
    await sync();
  }
  async function updateDoc(data) {
    const key = data.key
    let doc = await get(key);
    doc = { ...doc, ...data };
    await set(key, { ...doc });
    return doc;
  }

  async function sign(key) {
    let doc = await get(key);
    let sign = await signTypedData(doc);

    await set(key, { ...doc, signed: sign });
    await sync();
  }

  async function signTypedData(doc) {
    // TODO: Sign the documents
    // Use eth_signTypedData_v4
    const sign = "0xecb5b466601da9c5b3f59cd583047cb8d9cef7d078a822711bd50a14ffc8c70b16b2e66de99e1eda870c6f840de51be244705767313f0d23d2a73a1ebc5255c01b"
    await sleep(1000);

    return sign;
  }

  async function signAndUpload(apiKey, data) {
    const key = data.key;
    const accounts = await getAccounts();
    await signatureMergePdf(data)
    await sync();
    const doc = await updateDoc(data);

    try {
      // 1. Encrypt the file
      let { encryptedFile } = await encryptFile(accounts[0], doc);
      // 2. Upload to Lighthouse
      let lighthouseResponse = await uploadToLighthouse(apiKey, encryptedFile);
      // 3. Store the Lighthouse response in DB
      await set(key, { ...doc, lighthouse: lighthouseResponse.data });

      await sync();
    } catch (e) {
      console.warn(e);
      alert(JSON.stringify(e));
    }
  }

  async function downloadAndDecrypt(data) {
    const key = data.key;
    const cid = data.cid;

    try {
      const decryptedFileWithMetadata = await getLighthouseUpload(cid);

      const decryptedFile = decryptedFileWithMetadata.decryptedFile;

      const metadata = {
        ...decryptedFileWithMetadata.metadata
        , cid
      }

      let doc = await get(key);
      await set(key, { ...doc, metadata: metadata });

      let blob = new Blob([new Uint8Array(decryptedFile).buffer], { type: 'application/pdf' })
      let file = new File([blob], 'filename', { type: 'application/pdf' });

      await sync();
      app.ports.incoming.send({
        tag: "DECRYPTED_FILE_RECEIVED",
        data:
        {
          file: file,
          metadata: metadata
        }
      });

    } catch (e) {
      console.warn(e);
      alert(JSON.stringify(e));
    }
  }


  async function retrieve(data) {
    console.log(data);
    await downloadAndDecrypt(data);
  }

  async function sync() {
    const docs = await getAll();
    const keys = await getAllKeys();
    const dbDocs = (docs.map((x, i) => ({ key: (keys[i]), doc: x })));

    app.ports.incoming.send({
      tag: "GOT_DOCS",
      data: { docs: dbDocs },
    });
  }

  async function signatureMergePdf(data) {
    let doc = await get(data.key);

    // Load a PDFDocument from the existing PDF bytes
    const pdfDoc = await PDFDocument.load(
      await readAsArrayBuffer(doc.file)
    );

    // Embed the Helvetica font
    const helveticaFont = await pdfDoc.embedFont(StandardFonts.Helvetica)

    // Get the first page of the document
    const pages = pdfDoc.getPages()
    const firstPage = pages[0]

    // Get the width and height of the first page
    const { width, height } = firstPage.getSize()

    firstPage.drawText(data.signName, {
      x: 5,
      y: height / 2 + 300,
      size: 50,
      color: rgb(0.95, 0.1, 0.1),
    })

    // Serialize the PDFDocument to bytes (a Uint8Array)
    const pdfBytes = await pdfDoc.save()
    const file = new File([pdfBytes], doc.file.name, { type: 'application/pdf' });
    await set(data.key, { file: file });
  }
};
