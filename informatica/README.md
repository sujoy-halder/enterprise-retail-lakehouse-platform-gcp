# Informatica Assets

These files define implementation-ready mapping contracts for Informatica Cloud Data Integration or PowerCenter teams:

- `m_supplier_csv_to_gcs_bronze`: SFTP supplier CSV to GCS bronze with quarantine routing.
- `m_erp_inventory_cdc_to_pubsub`: ERP CDC to Pub/Sub with ordering keys and checkpoints.

The JSON files are intentionally tool-neutral specs. In a real tenant, map the named connections to IICS connections and import the parameter files for each environment.

