/*
=================== TRIGGER_TIMESTAMP ===================
*/
CREATE FUNCTION @extschema@.trigger_timestamp() RETURNS TRIGGER AS
$$
BEGIN
    NEW."updated_at" = NOW();
    NEW."created_at" = CASE WHEN TG_OP = 'INSERT' THEN NEW."updated_at" ELSE OLD."created_at" END;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql
    VOLATILE
    SECURITY DEFINER;
/*
=================== TIMESTAMP ===================
*/
CREATE TABLE @extschema@."timestamp"
(
    "created_at" TIMESTAMP NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE RULE "insert" AS ON INSERT TO @extschema@."timestamp" DO INSTEAD NOTHING;
CREATE RULE "update" AS ON UPDATE TO @extschema@."timestamp" DO INSTEAD NOTHING;
CREATE RULE "delete" AS ON DELETE TO @extschema@."timestamp" DO INSTEAD NOTHING;

CREATE TRIGGER "timestamp"
    BEFORE INSERT OR UPDATE
    ON @extschema@."timestamp"
    FOR EACH ROW
EXECUTE FUNCTION @extschema@.trigger_timestamp();
/*
=================== TIMESTAMP_DEL ===================
*/
CREATE TABLE @extschema@."timestamp_del"
(
    "deleted_at" TIMESTAMP
) INHERITS (@extschema@."timestamp");

CREATE RULE "insert" AS ON INSERT TO @extschema@."timestamp_del" DO INSTEAD NOTHING;
CREATE RULE "update" AS ON UPDATE TO @extschema@."timestamp_del" DO INSTEAD NOTHING;
CREATE RULE "delete" AS ON DELETE TO @extschema@."timestamp_del" DO INSTEAD NOTHING;

CREATE TRIGGER "timestamp"
    BEFORE INSERT OR UPDATE
    ON @extschema@."timestamp_del"
    FOR EACH ROW
EXECUTE FUNCTION @extschema@.trigger_timestamp();
