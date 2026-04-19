# Cloud Functions — academic-ally-app

## `stopBilling`

Billing hard-cap. Listens to the GCP budget's Pub/Sub topic; when monthly
spend exceeds the configured amount, detaches the billing account from
the project, disabling all paid Firebase/GCP services until a human
re-enables billing in the Firebase console.

This is the ONLY true spend cap Google provides — budget **alerts** do not
stop billing. See Google's official tutorial:

https://cloud.google.com/billing/docs/how-to/disable-billing-with-notifications

### One-time setup (required before first deploy works)

1. **Enable APIs** (Google Cloud Console, pick `academic-ally-app`):
   - Cloud Billing API — `https://console.cloud.google.com/apis/library/cloudbilling.googleapis.com`
   - Pub/Sub API — `https://console.cloud.google.com/apis/library/pubsub.googleapis.com`
   - Cloud Functions API — `https://console.cloud.google.com/apis/library/cloudfunctions.googleapis.com`
   - Cloud Build API — `https://console.cloud.google.com/apis/library/cloudbuild.googleapis.com`
   - Artifact Registry API — `https://console.cloud.google.com/apis/library/artifactregistry.googleapis.com`

2. **Create Pub/Sub topic** named exactly `billing-alerts`:
   `https://console.cloud.google.com/cloudpubsub/topic/list` → "Create Topic"

3. **Link the budget to that topic:**
   Go to `https://console.cloud.google.com/billing/budgets`, edit the
   `Firebase Project academic-ally-app` budget, scroll to
   "Manage notifications" and toggle "Connect a Pub/Sub topic to this
   budget" on. Select project `academic-ally-app` and topic
   `billing-alerts`. Save.

4. **Grant IAM role to the function's service account:**
   After first deploy, the auto-created service account
   `<project-number>-compute@developer.gserviceaccount.com` needs the
   **Billing Account Administrator** role on the billing account:

   `https://console.cloud.google.com/billing` → pick the billing account
   → IAM → Add principal → paste the service account email → assign role
   `Billing Account Administrator`.

   Without this role, the function can call
   `getProjectBillingInfo` but cannot actually detach billing.

### Deploying

From the project root (`academic_ally/`):

```bash
cd functions
npm install
cd ..
firebase deploy --only functions:stopBilling
```

The first deploy takes 5-10 minutes because GCP provisions Container
Registry, Cloud Build, etc. Subsequent deploys are fast.

### Testing without actually triggering

Publish a fake over-budget message to the Pub/Sub topic:

```bash
gcloud pubsub topics publish billing-alerts \
  --project=academic-ally-app \
  --message='{"costAmount":500,"budgetAmount":200,"currencyCode":"INR","budgetDisplayName":"test"}'
```

Then check logs:

```bash
firebase functions:log --only stopBilling
```

You should see "Budget exceeded... Disabling billing" but nothing actually
happens until the IAM role is granted (step 4 above). Once granted, **a
real trigger WILL disable billing** — make sure step 4 is the LAST thing
you do so you can test safely first.
