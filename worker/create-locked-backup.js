const fs = require('fs');
const path = require('path');

const srcFile = path.join(__dirname, 'kaapav-store', 'index.html');
const destFile1 = path.join(__dirname, 'kaapav-store', 'index.backup-locked.html');
const destDir = path.join(__dirname, 'kaapav-store-backup-locked');
const destFile2 = path.join(destDir, 'index.html');

if (!fs.existsSync(destDir)) {
  fs.mkdirSync(destDir, { recursive: true });
}

fs.copyFileSync(srcFile, destFile1);
fs.copyFileSync(srcFile, destFile2);

console.log('LOCKED BACKUP CREATED:');
console.log('1.', destFile1);
console.log('2.', destFile2);
