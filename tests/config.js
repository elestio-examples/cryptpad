module.exports = {
  httpUnsafeOrigin: "https://your.domain.com",
  httpSafeOrigin: "https://sandbox-your.domain.com",
  httpAddress: "0.0.0.0",
  // maxWorkers: 4,

  /* =====================
   *         Admin
   * ===================== */

  adminKeys: [""],
  adminEmail: "${ADMIN_EMAIL}",
  supportMailboxPublicKey: "",

  /* =====================
   *        STORAGE
   * ===================== */

  //inactiveTime: 90, // days
  //archiveRetentionTime: 15,
  //accountRetentionTime: 365,
  //disableIntegratedEviction: true,
  maxUploadSize: 150 * 1024 * 1024,
  //premiumUploadSize: 100 * 1024 * 1024,

  //1GB
  defaultStorageLimit: 1 * 1024 * 1024 * 1024,

  /* =====================
   *   DATABASE VOLUMES
   * ===================== */

  filePath: "./datastore/",
  archivePath: "./data/archive",
  pinPath: "./data/pins",
  taskPath: "./data/tasks",
  blockPath: "./block",
  blobPath: "./blob",
  blobStagingPath: "./data/blobstage",
  decreePath: "./data/decrees",
  logPath: "./data/logs",

  /* =====================
   *       Debugging
   * ===================== */

  cryptpad_content_security_enabled: "False",
  cryptpad_pad_content_security_enabled: "False",
  logToStdout: false,
  logLevel: "info",
  logFeedback: false,
  verbose: false,
  installMethod: "docker",
};
