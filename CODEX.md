## Root Cause

- sync_get_conduces is always called with an empty conduces array and without any last_sync hint (lib/src/providers/sync_provider.dart:423‑438), so after the initial download the backend has no way to know which conduces/     
  details need to be resent. Once the server assumes the device is up to date, the endpoint returns an empty list, dbHelper.addOrUpdateConduce is never executed again, and conduce_details keeps the quantities from the first   
  sync even though the method would overwrite them if fresh data arrived (lib/src/db_helper.dart:830‑879).

## Action Plan

    - Log/inspect the payload and response of the second sync_get_conduces call to confirm the server stops returning conduces after the first sync and document the API contract (does it expect last_sync, a list of local IDs with
      timestamps, or a force-refresh flag?).
    - Update _syncConduces to send the required delta information (e.g., include last_sync from DBHelper.getLastSyncDate() and/or pass the locally stored conduce IDs with their updated_at) so the backend can decide which conduces/
      details changed and must be returned.
    - Add a fallback path that requests a full refresh (e.g., omit last_sync or send a force_full=true flag) when the user manually re-syncs, so changes made outside the device are never missed.
    - After implementing the request changes, verify that addOrUpdateConduce is invoked on a second sync by checking the local DB (quantity updated from 3→1) and add an automated test or QA checklist covering “initial sync +      
      remote edit + second sync” to avoid regressions.    