-- триггер события для привязки триггера trigger_timestamp к таблице,
-- если таблица унаследована от таблиц timestamp или timestamp_del
CREATE FUNCTION event_trigger_add_triggers_from_timestamp_parent_tables ()
    RETURNS EVENT_TRIGGER
    AS $$
DECLARE
    "parents"              REGCLASS[];
    "tg_relid"             OID;
    "has_timestamp_parent" BOOLEAN = FALSE;
    "obj"                  RECORD;
BEGIN
    FOR "obj" IN
    SELECT *
    FROM pg_event_trigger_ddl_commands ()
        LOOP
            -- описание значений переменной obj
            -- @see https://www.postgresql.org/docs/current/functions-event-triggers.html#PG-EVENT-TRIGGER-DDL-COMMAND-END-FUNCTIONS
            RAISE DEBUG 'objid = %', "obj".objid; -- OID самого объекта
            RAISE DEBUG 'command_tag = %', "obj".command_tag; -- Тег команды
            RAISE DEBUG 'schema_name = %', "obj".schema_name; -- Имя схемы, к которой относится объект
            RAISE DEBUG 'object_type = %', "obj".object_type; -- Тип объекта
            RAISE DEBUG 'object_identity = %', "obj".object_identity; -- Текстовое представление идентификатора объекта, включающее схему
            RAISE DEBUG 'in_extension = %', "obj".in_extension; -- True, если команда является частью скрипта расширения
            -- не обрабатывать запрос, если запрос внутри расширения
            IF "obj".in_extension = TRUE THEN
                CONTINUE;
            END IF;
            -- список родительских таблиц, наследование которых проверяется
            "parents" = ARRAY ['@extschema@."timestamp"'::REGCLASS, '@extschema@."timestamp_del"'::REGCLASS];
            -- если создается таблица
            IF "obj".command_tag = 'CREATE TABLE' THEN
                "tg_relid" = "obj".objid;
                RAISE DEBUG USING MESSAGE = (concat('command_tag: CREATE TABLE ', "obj".object_identity));
                -- получение значение True, если текущая обрабатываемая таблица
                -- имеет наследование к таблицам timestamp или timestamp_del
                "has_timestamp_parent" = (
                    SELECT exists(
                        -- запрос на получение информации из таблицы наследований,
                        -- где inhrelid равен текущей обрабатываемой таблице
                        -- и inhparent равен таблице timestamp или timestamp_del
                        SELECT p.oid
                        FROM pg_inherits
                            JOIN pg_class AS c ON (inhrelid = c.oid)
                            JOIN pg_class AS p ON (inhparent = p.oid)
                        WHERE c.oid = "tg_relid"
                            AND p.oid = ANY ("parents")
                        )
                );
                -- если таблица создана с использованием наследования к таблицам timestamp или timestamp_del
                IF "has_timestamp_parent" THEN
                    EXECUTE format('
                        CREATE TRIGGER "timestamp"
                            BEFORE INSERT OR UPDATE
                            ON %s
                            FOR EACH ROW
                        EXECUTE FUNCTION @extschema@.trigger_timestamp();', "tg_relid"::REGCLASS);
                END IF;
            END IF;
        END LOOP;
END
$$
LANGUAGE plpgsql
VOLATILE;

