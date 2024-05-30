* [x] Allow user to connect Filecoin (Metamask on Filecoin/IPFS network) wallet
* [x] Load the PDF document into SPA (local storage)
* [x] Retrive docs
* [x] Upload PDf to Lighthouse storage
* [ ] We should have a list of wallet to which encrypt.
* [ ] Sign PDF document
* [x] Encrypt the PDF document locally.

## How to develop

### Installation

To get started, we'll need to install the latest version of Elm Land from NPM.

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

### Testing using local CloudFlare Pages

```
npm run build && npx wrangler pages dev dist/
```

### Envirnoment variables

It is necessary to set the "VITE_LIGHTHOUSE_API_KEY" environment variable in order to upload to Lighouse storage



### Issues

* [ ] Some of the PDFs larger than 1MB are not displaying properly in the preview modal window. 
  The solution here: [Open base64 encoded pdf file using javascript. Issue with file size larger than 2 MB](https://stackoverflow.com/questions/16245767/creating-a-blob-from-a-base64-string-in-javascript)
