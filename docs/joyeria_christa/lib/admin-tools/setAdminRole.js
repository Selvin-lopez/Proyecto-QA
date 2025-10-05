// 📁 admin-tools/setAdminRole.js
const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

// Inicializar Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const uid = "8XMjfEPOzwgK2E64gVaoL7VUeRp2"; // 👈 UID del usuario admin

async function setAdminRole() {
  try {
    await admin.auth().setCustomUserClaims(uid, { admin: true });
    console.log(`✅ Rol admin asignado correctamente al UID: ${uid}`);
    process.exit();
  } catch (error) {
    console.error("❌ Error al asignar rol:", error);
    process.exit(1);
  }
}

setAdminRole();
