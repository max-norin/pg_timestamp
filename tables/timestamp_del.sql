-- таблица с полями created_at, updated_at, deleted_at для использования в наследовании
CREATE TABLE "timestamp_del"
(
    "deleted_at" TIMESTAMP
) INHERITS (@extschema@."timestamp");
-- запрет на вставку, обновление и удаление данных в таблице
CREATE RULE "insert" AS ON INSERT TO "timestamp_del" DO INSTEAD NOTHING;
CREATE RULE "update" AS ON UPDATE TO "timestamp_del" DO INSTEAD NOTHING;
CREATE RULE "delete" AS ON DELETE TO "timestamp_del" DO INSTEAD NOTHING;

-- создание триггера на автоматическое обновление полей created_at, updated_at
CREATE TRIGGER "timestamp"
    BEFORE INSERT OR UPDATE
    ON "timestamp_del"
    FOR EACH ROW
EXECUTE FUNCTION @extschema@.trigger_timestamp();
