/**
 * Set admin role for a user by email
 * Usage: node scripts/set-admin.js <email>
 */

const admin = require('firebase-admin');
const serviceAccount = require('../functions/service-account-key.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

async function setAdminByEmail(email) {
  try {
    // Get user by email
    console.log(`Looking for user with email: ${email}`);
    const user = await admin.auth().getUserByEmail(email);
    console.log(`Found user: ${user.uid}`);

    // Set admin custom claim
    await admin.auth().setCustomUserClaims(user.uid, { admin: true });
    console.log(`✅ Admin role set for ${email} (UID: ${user.uid})`);

    // Also update Firestore
    await admin.firestore().collection('users').doc(user.uid).set(
      { isAdmin: true },
      { merge: true }
    );
    console.log(`✅ Firestore user document updated`);

    console.log('\n🎉 Admin setup complete!');
    console.log('Please have the user sign out and sign in again for changes to take effect.');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

// Get email from command line argument
const email = process.argv[2];

if (!email) {
  console.error('Usage: node scripts/set-admin.js <email>');
  process.exit(1);
}

setAdminByEmail(email);
