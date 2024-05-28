import { openDB } from 'idb';

export function initDB() {
  openDB('web3signDB', 1, {
    upgrade(db) {
      db.createObjectStore('docs', { autoIncrement: true });
    },
  });
}

export async function upload(data) {
  const db = await openDB('web3signDB', 1);
  db.add('docs', { name: data.name, file: data });
  db.close();
}

export async function getAll() {
  const db = await openDB('web3signDB', 1);
  const docs = db.getAll('docs');
  db.close();
  return docs;
}
// export function upload(data) {
//   const dbName = "web3sign";
//   const request = indexedDB.open(dbName, 1);

//   request.onerror = (e) => {
//     console.error(`Database error: ${e.target.errorCode}`);
//   };

//   request.onupgradeneeded = function (e) {
//     let thisDb = e.target.result;

//     if (!thisDb.objectStoreNames.contains("docs")) {
//       var objectStore = thisDb.createObjectStore("docs", {
//         keyPath: "id",
//         autoIncrement: true,
//       });
//       objectStore.createIndex("searchkey", "searchkey", { unique: false });
//     }
//   };

//   request.onsuccess = (event) => {
//     console.log("running onsuccess");
//     let thisDb = event.target.result;
//     let docs = thisDb.transaction(["docs"], "readwrite").objectStore("docs");
//     docs.add({ name: data.name, file: data });
//   };
// }

// export function getAll() {
//   const dbName = "web3sign";
//   const request = indexedDB.open(dbName, 1);

//   request.onerror = (e) => {
//     console.error(`Database error: ${e.target.errorCode}`);
//   };

//   request.onupgradeneeded = function (e) {
//     let thisDb = e.target.result;

//     if (!thisDb.objectStoreNames.contains("docs")) {
//       var objectStore = thisDb.createObjectStore("docs", {
//         keyPath: "id",
//         autoIncrement: true,
//       });
//       objectStore.createIndex("searchkey", "searchkey", { unique: false });
//     }
//   };

//   request.onsuccess = (e) => {
//     const db = e.target.result;
//     const objectStore = db.transaction("docs").objectStore("docs");

//     let docs = []; 

//     objectStore.openCursor().onsuccess = (event) => {
//       const cursor = event.target.result;
//       if (cursor) {
//         docs.push(cursor.value);
//         cursor.continue();
//       } else {
//         console.log(`Got all docs: ${docs.map(x => x.name)}`);
//       }
//     }
//   };
// }
