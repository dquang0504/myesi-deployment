truncate payment_audit;
truncate billing_events;
truncate checkout_records;
update organizations set subscription_id = 1 where id = 1;
delete from subscriptions where id = 2;
truncate invoices;