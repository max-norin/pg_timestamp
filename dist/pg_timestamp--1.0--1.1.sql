/*
=================== TIMESTAMP ===================
*/
CREATE RULE "timestamp_del__update" AS ON UPDATE TO @extschema@."timestamp" DO INSTEAD NOTHING;
CREATE RULE "timestamp_del__delete" AS ON DELETE TO @extschema@."timestamp" DO INSTEAD NOTHING;
/*
=================== TIMESTAMP_DEL ===================
*/
CREATE RULE "timestamp_del__update" AS ON UPDATE TO @extschema@."timestamp_del" DO INSTEAD NOTHING;
CREATE RULE "timestamp_del__delete" AS ON DELETE TO @extschema@."timestamp_del" DO INSTEAD NOTHING;
/*
=================== ADD_TRIGGERS_FROM_TIMESTAMP_PARENT_TABLES ===================
*/
CREATE OR REPLACE FUNCTION event_trigger_add_triggers_from_timestamp_parent_tables ()
    RETURNS EVENT_TRIGGER
AS $$
DECLARE
    "parents"              REGCLASS[];
    "has_timestamp_parent" BOOLEAN = FALSE;
    "obj"                  RECORD;
BEGIN
    FOR "obj" IN
        SELECT *
        FROM pg_event_trigger_ddl_commands ()
        LOOP
            IF "obj".in_extension = TRUE THEN
                CONTINUE;
            END IF;
            "parents" = ARRAY ['@extschema@."timestamp"'::REGCLASS, '@extschema@."timestamp_del"'::REGCLASS];
            IF "obj".command_tag = 'CREATE TABLE' THEN
                "has_timestamp_parent" = (
                    SELECT exists(
                        SELECT inhrelid
                        FROM pg_inherits
                        WHERE inhrelid = "obj".objid
                          AND inhparent = ANY ("parents")
                    )
                );
                IF "has_timestamp_parent" THEN
                    EXECUTE format('
                        CREATE TRIGGER "timestamp"
                            BEFORE INSERT OR UPDATE
                            ON %s
                            FOR EACH ROW
                        EXECUTE FUNCTION @extschema@.trigger_timestamp();', "obj".objid::REGCLASS);
                END IF;
            END IF;
        END LOOP;
END
$$
    LANGUAGE plpgsql
    VOLATILE;
