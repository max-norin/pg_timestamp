-- таблица с полями created_at, updated_at, deleted_at для использования в наследовании
CREATE TABLE "timestamp_del"
(
    "deleted_at" TIMESTAMP
) INHERITS (@extschema@."timestamp");
-- запрет на вставку данных в таблицу
CREATE RULE "timestamp_del__insert" AS ON INSERT TO "timestamp_del" DO INSTEAD NOTHING;

-- создание триггера на автоматическое обновление полей created_at, updated_at
CREATE TRIGGER "timestamp"
    BEFORE INSERT OR UPDATE
    ON "timestamp_del"
    FOR EACH ROW
EXECUTE FUNCTION @extschema@.trigger_timestamp();
