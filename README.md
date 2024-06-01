## How It Works

Step 1: Connect your MetaMask wallet to the browser.

Step 2: Upload the PDF document to the browser's client-storage, IndexedDB.

Step 3: Sign the PDF document with your name.

Step 4: Input the MetaMask address of the other party involved.

Step 5: Use the Lit JS SDK to encrypt the document for secure sharing.

Step 6: Upload the encrypted document to IPFS using the Lighthouse JS SDK.

Step 7: Share the Content Identifier (CID) of the uploaded document with the other party.

Step 8: The other party repeats the process from Step 1 and shares the CID of the newly uploaded document with you.


## How to develop

### Installation

```
npm i
```

### Run the development server

```
npm run dev
```

### Building the app

```
npm run build
```

### Envirnoment variables

It is necessary to set the "VITE_LIGHTHOUSE_API_KEY" environment variable in order to upload to Lighouse storage


### Issues

* [ ] Some of the PDFs larger than 1MB are not displaying properly in the preview modal window. 
  The solution here: [Open base64 encoded pdf file using javascript. Issue with file size larger than 2 MB](https://stackoverflow.com/questions/16245767/creating-a-blob-from-a-base64-string-in-javascript)
