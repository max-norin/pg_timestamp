# pg_timestamp

> Расширение позволяет с помощью наследования создавать таблицы с timestamp метками.

## Основное

### Установка

Скачайте себе в папку `extension` PostgreSQL файлы из [dist](./dist) и выполните следующие команды.

Создайте новую схему для удобства.

```postgresql
CREATE SCHEMA "abstract";
ALTER ROLE "postgres" SET search_path TO "public", "abstract";
```

Установите расширение.

```postgresql
CREATE EXTENSION "pg_timestamp"
    SCHEMA "abstract"
    VERSION '1.0';
```

[Подробнее про расширение и файл control](https://postgrespro.ru/docs/postgresql/14/extend-extensions)

### Использование

Расширение имеет две родительские таблицы `"timestamp"` и `"timestamp_del"`.

#### Таблица `"timestamp"`

Таблица `"timestamp"` имеет колонки `"created_at"`, `"updated_at"` + триггер, который обновляет эти
поля.
Определять новую таблицу можно следующим образом.

```postgresql
CREATE TABLE "user"
(
    "id"       SERIAL PRIMARY KEY,
    "nickname" VARCHAR(100) NOT NULL UNIQUE
) INHERITS ("timestamp");
```

Событийный триггер узнает, что создается таблица с родительской таблицей `"timestamp"` и
автоматически добавит триггер.

#### Таблица `"timestamp_del"`

Таблица `"timestamp_del"` в дополнении к вышесказанному имеет поле `"deleted_at"`.

```postgresql
CREATE TABLE "user"
(
    "id"       SERIAL PRIMARY KEY,
    "nickname" VARCHAR(100) NOT NULL UNIQUE
) INHERITS ("timestamp_del");
```

## Рекомендуемое использование

Для безопасности данных временных меток предлагаю сделать две роли: администратор и пользователь.
Пользователю будет запрещено редактировать временные метки.
Это позволит показать, что пользователь не имеет права их редактировать.
Временные метки будут назначаться только в функции триггера после вставки или обновлении записи,
поэтому редактировать можно будет только,
если назначить триггер после триггера временных меток,
или случайно не назначить триггер, или отключить его.
Роли обезопасят данные от таких случаев.

Для реализации этого подхода функция триггера запускается от имени создателя функции.
Это несет угрозу безопасности данных,
чтобы никто другой не мог воспользоваться этой функцией заблокируем к ней доступ.

```postgresql
-- запрещает всем выполнение функции trigger_timestamp
REVOKE ALL ON ROUTINE trigger_timestamp() FROM PUBLIC;
-- разрешает выполнение функции trigger_timestamp администратору
GRANT ALL ON ROUTINE trigger_timestamp() TO "postgres";
```

```postgresql
-- таблица пользователей с временными метками
CREATE TABLE "user"
(
    "id"       SERIAL PRIMARY KEY,
    "nickname" VARCHAR(100) NOT NULL UNIQUE
) INHERITS ("timestamp");
```

Создаем пользователя и ограничиваем его права.

```postgresql
-- создаем пользователя
CREATE ROLE "test_timestamp" LOGIN;
-- разрешаем подключаться к базе данных
GRANT CONNECT ON DATABASE "postgres" TO "test_timestamp";
-- даем нужные доступы для пользователя
-- ключевой момент, что нет доступа на редактирование временных меток 
GRANT INSERT ("id", "nickname"), UPDATE ("id", "nickname"), SELECT ON TABLE "user" TO "test_timestamp";
```

Меняем текущего пользователя на нового пользователя или
подключаемся к базе с помощью нового пользователя.

```postgresql
SET ROLE "test_timestamp";
```

Попробуем вставить с колонкой `"created_at"` - ошибка.

```postgresql
INSERT INTO "user" (id, nickname, created_at)
VALUES (DEFAULT, 'max', DEFAULT);   
```

Попробуем вставить без колонки `"created_at"` - успешно.

```postgresql
INSERT INTO "user" (id, nickname)
VALUES (DEFAULT, 'max');
```

## Файлы

- `tables/*.sql` определение родительских таблиц `"timestamp"` `"timestamp_del"`
- [triggers/timestamp.sql](./triggers/timestamp.sql) триггер для родительских таблиц
- [event_triggers/add_triggers_from_timestamp_parent_tables.sql](./event_triggers/add_triggers_from_timestamp_parent_tables.sql)
  функция событийного триггер
- [init.sql](./init.sql) назначение событийного триггера
- [test/*.sql](./test) тестовые файлы

## Полезное

- [Pseudotypes](https://www.postgresql.org/docs/current/datatype-pseudo.html)
- [Functions with Variable Numbers of Arguments](https://www.postgresql.org/docs/current/xfunc-sql.html#XFUNC-SQL-VARIADIC-FUNCTIONS)
- [Object Identifier Types](https://www.postgresql.org/docs/current/datatype-oid.html#DATATYPE-OID-TABLE)
