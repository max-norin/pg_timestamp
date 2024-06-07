# pg_timestamp

100% работает на PostgreSQL 16 версии, на остальных не проверял.
Если у вас есть информация, что работает на более ранних версиях
сообщите мне.

> Расширение для PostgreSQL, позволяющее с помощью наследования таблиц
> создавать таблицы с timestamp метками: created_at, updated_at, deleted_at.

Примечание: при удалении наследования командой
`ALTER TABLE public.new_users NO INHERIT public.users;`
никаких дополнительных действий не произойдёт. Таблица будет иметь
те же столбцы, ограничения и триггеры, как при наследовании.
Включая автоматически наследуемые ограничения `CHECK` и `NOT NULL`.

# Установка

Для работы версии 2.0 потребуется добавить расширение
[pg_full_inherit](https://github.com/max-norin/pg_full_inherit)
в приложение PostgreSQL.
Это расширение позволяет делать полное наследование таблиц
включая автоматическое наследование триггеров, что необходимо
и обязательно для работы текущего расширения. В более ранних версиях
использовался собственный метод автоматического добавления триггеров
в наследуемые таблицы.

## Классическая

Скачайте файлы `pg_timestamp--2.0.sql` и `pg_timestamp.control` из [dist](./dist)
и переместите их в папку `extension` приложения PostgreSQL.
Для windows папка может располагаться в
`C:\Program Files\PostgreSQL\16\share\extension`.
Далее выполните следующие команды.

Создайте новую схему для удобства.

```sql
CREATE SCHEMA "abstract";
ALTER ROLE "postgres" SET search_path TO "public", "abstract";
```

Установите расширение.

```sql
CREATE EXTENSION "pg_timestamp"
    SCHEMA "abstract"
    VERSION '2.0';
```

[Подробнее про расширение и файл control](https://postgrespro.ru/docs/postgresql/current/extend-extensions)

## Обходной путь

Если нет возможности добавить расширение в PostgreSQL, то есть другой вариант.
Скопировать в текстовый редактор содержание файла `pg_timestamp--2.0.sql`
из [dist](./dist). Заменить выражение `@extschema@` на схему,
в которую будет добавлены необходимые функции, например `abstract`.
Скопировать в консоль PostgreSQL и запустить.

# Использование

Расширение имеет две родительские таблицы `"timestamp"` и `"timestamp_del"`.

## Таблица `"timestamp"`

Таблица `"timestamp"` имеет колонки `"created_at"`, `"updated_at"` и триггер,
который обновляет эти поля.
Определить новую дочернюю таблицу можно следующим образом.

```postgresql
CREATE TABLE "user"
(
    "id"       SERIAL PRIMARY KEY,
    "nickname" VARCHAR(100) NOT NULL UNIQUE
) INHERITS ("abstract"."timestamp");
```

Событийный триггер из расширения

узнает, что создается таблица, которая наследуется от таблицы `"timestamp"`, и
автоматически добавит триггер.

## Таблица `"timestamp_del"`

Таблица `"timestamp_del"` в дополнении к таблице `"timestamp"` имеет поле `"deleted_at"`.
Определить новую дочернюю таблицу можно следующим образом.

```postgresql
CREATE TABLE "user"
(
    "id"       SERIAL PRIMARY KEY,
    "nickname" VARCHAR(100) NOT NULL UNIQUE
) INHERITS ("abstract"."timestamp_del");
```

# Рекомендуемое использование

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
