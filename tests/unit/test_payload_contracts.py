from datetime import UTC, datetime


def test_pos_transaction_contract() -> None:
    event = {
        "transaction_id": "txn-001",
        "store_id": "store-001",
        "customer_id": "cust-001",
        "product_id": "sku-001",
        "quantity": 2,
        "unit_price": "12.30",
        "currency": "USD",
        "event_time": datetime.now(UTC).isoformat(),
    }

    required = {"transaction_id", "store_id", "product_id", "quantity", "event_time"}
    assert required.issubset(event)
    assert event["quantity"] >= 0


def test_inventory_cdc_contract() -> None:
    event = {
        "inventory_event_id": "inv-001",
        "store_id": "store-001",
        "sku": "sku-001",
        "operation": "UPSERT",
        "on_hand_quantity": 100,
        "reserved_quantity": 5,
        "event_time": datetime.now(UTC).isoformat(),
    }

    assert event["operation"] in {"INSERT", "UPDATE", "UPSERT", "DELETE"}
    assert event["on_hand_quantity"] >= event["reserved_quantity"]

