/**
 * @file bootstrap_admin.js
 * CLI script to securely bootstrap the initial Stage Administrator.
 *
 * Requirements:
 * - Explicit UID required via --uid=<UID> or process.env.BOOTSTRAP_UID.
 * - Refuses placeholder or empty UIDs.
 * - Supports --dry-run and --apply.
 */

const { validateProject } = require('./migrate_v2');

function parseBootstrapArgs(argv = process.argv.slice(2)) {
  const options = {
    uid: process.env.BOOTSTRAP_UID || null,
    name: null,
    email: '',
    dryRun: true,
    project: null,
  };

  for (const arg of argv) {
    if (arg === '--dry-run') {
      options.dryRun = true;
    } else if (arg === '--apply') {
      options.dryRun = false;
    } else if (arg.startsWith('--uid=')) {
      options.uid = arg.split('=')[1].trim();
    } else if (arg.startsWith('--name=')) {
      options.name = arg.split('=')[1].trim();
    } else if (arg.startsWith('--email=')) {
      options.email = arg.split('=')[1].trim();
    } else if (arg.startsWith('--project=')) {
      options.project = arg.slice('--project='.length);
    } else {
      throw new Error('Unknown bootstrap option');
    }
  }

  validateProject(options.project);
  return options;
}

function validateUid(uid) {
  if (!uid || typeof uid !== 'string' || uid.trim().length === 0 || uid.includes('/') || uid.length > 128) {
    throw new Error('Bootstrap requires an explicit non-empty UID. Pass --uid=<Firebase_Auth_UID>');
  }

  const trimmed = uid.trim();
  if (trimmed === 'admin' || trimmed === 'placeholder' || trimmed === 'test-uid' || trimmed === 'example') {
    throw new Error(`Rejected placeholder UID: "${trimmed}". Provide a valid Firebase Auth UID.`);
  }

  return trimmed;
}

async function bootstrapAdmin(db, options) {
  validateProject(options.project, db);
  const validUid = validateUid(options.uid);

  const adminPayload = {
    role: 'stageAdmin',
    status: 'active',
    grade: 'all',
    isApproved: true,
    updatedAt: new Date(),
  };

  if (options.name) {
    adminPayload.name = options.name;
  }
  if (options.email) {
    adminPayload.email = options.email;
  }

  const ref = db.collection('khodam').doc(validUid);
  const existing = await ref.get();
  if (!existing.exists) throw new Error('Bootstrap requires an existing authenticated profile');
  if (options.dryRun !== false) {
    return {
      success: true,
      dryRun: true,
      uid: validUid,
      payload: adminPayload,
      message: `[DRY-RUN] Would grant stageAdmin privileges to UID: ${validUid}`,
    };
  }

  await db.runTransaction(async tx => {
    const current = await tx.get(ref);
    if (!current.exists || current.data().status === 'deleting') throw new Error('Existing eligible profile required');
    tx.update(ref, adminPayload);
  });

  return {
    success: true,
    dryRun: false,
    uid: validUid,
    payload: adminPayload,
    message: `[APPLY] Successfully granted stageAdmin privileges to UID: ${validUid}`,
  };
}

if (require.main === module) {
  (async () => {
    const options = parseBootstrapArgs();
    const admin = require('firebase-admin');
    const app = admin.initializeApp({ projectId: options.project });
    try {
      await app.auth().getUser(validateUid(options.uid));
      const result = await bootstrapAdmin(app.firestore(), options);
      console.log(result.dryRun ? 'Bootstrap dry-run validated existing UID' : 'Bootstrap grant committed');
    } finally { await app.delete(); }
  })().catch(() => { console.error('Bootstrap failed: verify project, existing Auth UID and eligible profile'); process.exitCode = 1; });
}

module.exports = {
  parseBootstrapArgs,
  validateUid,
  bootstrapAdmin,
};
