const fs = require('fs');
const s = fs.readFileSync('D:/03082026/PcFolder/ATT_APP_Mobile/www/index.html', 'utf8');

function extract(name, len = 2500) {
  const i = s.indexOf('function ' + name);
  if (i < 0) { console.log('NOT FOUND', name); return; }
  console.log('\n=== ' + name + ' ===\n');
  console.log(s.substring(i, i + len));
}

extract('notifyAdmins', 3500);
extract('startAdminActivityNotifications', 2000);
extract('addNotification', 1500);
extract('showNativeNotification', 800);

const keys = ['check_in', 'check_out', 'manager_login', 'collection(\'notifications\''];
keys.forEach(k => {
  let idx = 0, n = 0;
  while ((idx = s.indexOf(k, idx + 1)) >= 0 && n < 5) {
    console.log('\n--- ' + k + ' @ ' + idx + ' ---');
    console.log(s.substring(Math.max(0, idx - 80), idx + 200).replace(/\n/g, ' '));
    n++;
  }
});
