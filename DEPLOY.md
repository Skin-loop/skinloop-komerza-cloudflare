# Deployment runbook

1. Create a dedicated Cloudflare account/API authorization owned by the
   merchant. From this directory run `wrangler login`; the provisioning script
   uses that session and does not read or write credentials.
2. Run `bash scripts/provision.sh`; it creates queues/DLQ and D1, captures the
   D1 ID, updates config, and applies remote migrations. It does not deploy.
3. Set `KOMERZA_STORE_ID` and `SHOP_URL` in `wrangler.toml`; Skinloop API and
   hosted checkout URLs are preconfigured. The Worker defaults to a
   1.20 USD/EUR rate, 500 BPS FX buffer, and 3600-second checkout lifetime.
4. Add the encrypted secrets available before deployment:

   ```sh
   wrangler secret put SKINLOOP_API_KEY
   wrangler secret put KOMERZA_API_KEY
   ```

5. Run `bash scripts/deploy.sh`. Open the assigned Worker URL and copy its
   `webhookEndpoint`. Register that URL in Skinloop for
   `payment.pending`, `payment.completed`, and `payment.reverted`.
6. Save the one-time secret returned by Skinloop, then verify the endpoint:

   ```sh
   wrangler secret put SKINLOOP_WEBHOOK_SECRET_CURRENT
   ```

   Until this secret exists, the Worker exposes only its setup response and all
   payment processing fails closed. During rotation, put the old secret in
   `SKINLOOP_WEBHOOK_SECRET_PREVIOUS`.
7. Confirm the queue consumer has one-message batches, five-second timeout,
   ten retries, and the dedicated DLQ. Run the documented low-value smoke
   sequence before enabling the storefront button.

Never commit `wrangler.toml` values containing secrets, `.env` files, API
tokens, webhook signatures, or customer email addresses. Rotation procedure:
put the old secret in `SKINLOOP_WEBHOOK_SECRET_PREVIOUS`, replace current,
verify deliveries, then remove the previous secret.