CREATE FUNCTION event_trigger_add_triggers_from_timestamp_parent_tables ()
    RETURNS EVENT_TRIGGER
    AS $$
DECLARE
    "parents" CONSTANT     REGCLASS[] = ARRAY ['"timestamp"'::REGCLASS, '"timestamp_del"'::REGCLASS];
    "tg_relid"             OID;
    "has_timestamp_parent" BOOLEAN    = FALSE;
    "obj"                  RECORD;
BEGIN
    FOR "obj" IN
    SELECT *
    FROM pg_event_trigger_ddl_commands ()
        LOOP
            RAISE DEBUG 'objid = %', "obj".objid;
            RAISE DEBUG 'command_tag = %', "obj".command_tag;
            RAISE DEBUG 'schema_name = %', "obj".schema_name;
            RAISE DEBUG 'object_type = %', "obj".object_type;
            RAISE DEBUG 'object_identity = %', "obj".object_identity;
            RAISE DEBUG 'in_extension = %', "obj".in_extension;
            IF "obj".in_extension = TRUE THEN
                CONTINUE;
            END IF;
            IF "obj".command_tag = 'CREATE TABLE' THEN
                "tg_relid" = "obj".objid;
                RAISE DEBUG USING MESSAGE = (concat('command_tag: CREATE TABLE ', "obj".object_identity));
                -- parent tables of the created table
                "has_timestamp_parent" = (
                    SELECT exists(
                        SELECT p.oid
                        FROM pg_inherits
                            JOIN pg_class AS c ON (inhrelid = c.oid)
                            JOIN pg_class AS p ON (inhparent = p.oid)
                        WHERE c.oid = "tg_relid"
                            AND p.oid = ANY ("parents")
                        )
                );
                -- if the created table has parents in timestamp
                IF "has_timestamp_parent" THEN
                    EXECUTE format('
                        CREATE TRIGGER "timestamp"
                            BEFORE INSERT OR UPDATE
                            ON %s
                            FOR EACH ROW
                        EXECUTE FUNCTION trigger_timestamp();', "tg_relid"::REGCLASS);
                END IF;
            END IF;
        END LOOP;
END
$$
LANGUAGE plpgsql
VOLATILE;

