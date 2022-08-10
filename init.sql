-- Chapter 40. Event Triggers - https://postgresql.org/docs/current/event-triggers.html
-- Event Trigger Functions - https://postgresql.org/docs/current/functions-event-triggers.html
-- Event Trigger Firing Matrix - https://postgresql.org/docs/current/event-trigger-matrix.html
CREATE EVENT TRIGGER "add_triggers_from_timestamp_parent_tables" ON ddl_command_end
    WHEN TAG IN ('CREATE TABLE', 'ALTER TABLE')
        EXECUTE PROCEDURE @extschema@.event_trigger_add_triggers_from_timestamp_parent_tables ();

