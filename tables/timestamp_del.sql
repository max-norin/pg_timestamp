CREATE TABLE "timestamp_del"
(
    "deleted_at" TIMESTAMP
) INHERITS (@extschema@."timestamp");
CREATE RULE "timestamp_del__insert" AS ON INSERT TO "timestamp_del" DO INSTEAD NOTHING;

CREATE TRIGGER "timestamp"
    BEFORE INSERT OR UPDATE
    ON "timestamp_del"
    FOR EACH ROW
EXECUTE FUNCTION @extschema@.trigger_timestamp();
