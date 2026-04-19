/**
 * Billing hard-cap for Academic Ally.
 *
 * Listens to the Pub/Sub topic `billing-alerts` that the GCP budget fires
 * to. When a notification arrives indicating cumulative monthly cost has
 * exceeded the configured budget, this function DETACHES the billing
 * account from the `academic-ally-app` project. All paid Firebase/GCP
 * services stop working immediately (Firestore beyond free tier, Storage,
 * Cloud Functions themselves, etc.) until someone manually re-links a
 * billing account via the Firebase / GCP console.
 *
 * This is the ONLY hard cap Google provides — budget alerts alone do not
 * stop billing. Reference:
 *   https://cloud.google.com/billing/docs/how-to/disable-billing-with-notifications
 *
 * Once this function disables billing, re-enabling requires a human:
 *   Firebase Console → Usage → Details → re-upgrade to Blaze and link a
 *   billing account. Intentional friction — prevents a runaway loop.
 */

const { onMessagePublished } = require('firebase-functions/v2/pubsub');
const { CloudBillingClient } = require('@google-cloud/billing');

const PROJECT_ID = 'academic-ally-app';
const PROJECT_NAME = `projects/${PROJECT_ID}`;

const billing = new CloudBillingClient();

exports.stopBilling = onMessagePublished(
  {
    topic: 'billing-alerts',
    region: 'asia-south1', // Mumbai — closest to IN users, lowest latency for billing event delivery
  },
  async (event) => {
    const data = event.data.message.json ?? {};
    console.log('Budget notification received:', JSON.stringify(data));

    // Expected fields from a GCP budget Pub/Sub message:
    //   budgetDisplayName, costAmount, budgetAmount, currencyCode,
    //   costIntervalStart, alertThresholdExceeded (optional).
    const cost = Number(data.costAmount);
    const limit = Number(data.budgetAmount);

    if (!Number.isFinite(cost) || !Number.isFinite(limit)) {
      console.log('Ignoring malformed notification.');
      return;
    }

    if (cost <= limit) {
      console.log(
        `Within budget — cost=${cost} ${data.currencyCode ?? ''}, limit=${limit}. No action.`
      );
      return;
    }

    const enabled = await isBillingEnabled(PROJECT_NAME);
    if (!enabled) {
      console.log('Billing already disabled. Nothing to do.');
      return;
    }

    console.warn(
      `⚠ Budget exceeded (cost=${cost} > limit=${limit}). Disabling billing for ${PROJECT_ID}.`
    );
    const result = await disableBillingForProject(PROJECT_NAME);
    console.warn('Billing disabled.', JSON.stringify(result));
  }
);

async function isBillingEnabled(projectName) {
  try {
    const [info] = await billing.getProjectBillingInfo({ name: projectName });
    return Boolean(info.billingEnabled);
  } catch (err) {
    // Fail-safe: if we can't determine the state, assume billing is on so
    // the next step (disable) is at least attempted.
    console.error('getProjectBillingInfo failed:', err);
    return true;
  }
}

async function disableBillingForProject(projectName) {
  const [info] = await billing.updateProjectBillingInfo({
    name: projectName,
    projectBillingInfo: { billingAccountName: '' },
  });
  return info;
}
