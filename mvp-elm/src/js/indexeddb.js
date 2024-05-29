import { openDB } from 'idb';

const dbPromise = openDB('web3signDB', 1, {
  upgrade(db) {
    db.createObjectStore('docs', { autoIncrement: true });
  },
});

export async function upload(data) {
  return (await dbPromise).
    put('docs', { name: data.name, file: data });
}
export async function get(key) {
  return (await dbPromise).get('docs', key);
}
export async function set(key, val) {
  return (await dbPromise).put('docs', val, key);
}
export async function del(key) {
  return (await dbPromise).delete('docs', key);
}
export async function clear() {
  return (await dbPromise).clear('docs');
}
export async function getAll() {
  return (await dbPromise).getAll('docs');
}
export async function getAllKeys() {
  return (await dbPromise).getAllKeys('docs');
}
