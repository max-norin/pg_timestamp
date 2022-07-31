# pg_timestamp

> The extension allows you to create tables with timestamp using inheritance.

[README in Russian](./README.ru.md)

## Getting Started

### Install

Download the files from [dist](./dist) to your `extension` folder PostgreSQL and run the following
commands.

Create a new schema for convenience.

```postgresql
CREATE SCHEMA "abstract";
ALTER ROLE "postgres" SET search_path TO "public", "abstract";
```

Install the extension.

```postgresql
CREATE EXTENSION "pg_timestamp"
    SCHEMA "abstract"
    VERSION '1.0';
```

### Usage

The extension has two parent tables`"timestamp"` and `"timestamp_del"`.

#### `"timestamp"` table

The `"timestamp"` table has `"created_at"`, `"updated_at"` columns + a trigger that updates these
columns.
You can create a new table as follows.

```postgresql
CREATE TABLE "user"
(
    "id"       SERIAL PRIMARY KEY,
    "nickname" VARCHAR(100) NOT NULL UNIQUE
) INHERITS ("timestamp");
```

The event trigger knows that the table is being created with the `"timestamp"` parent table and will
automatically add the trigger.

#### `"timestamp_del"` table

The table `"timestamp_del"` in addition to the above has `"deleted_at"` column.

```postgresql
CREATE TABLE "user"
(
    "id"       SERIAL PRIMARY KEY,
    "nickname" VARCHAR(100) NOT NULL UNIQUE
) INHERITS ("timestamp_del");
```

## Recommended use

For the security of timestamp data, I suggest creating two roles: administrator and user.
The user will not be able to edit timestamps.
This will show that the user does not have permission to edit them.
Timestamps will only be assigned in the trigger function after inserting or updating a record,
so you can only edit
if you are assigning a trigger after the timestamp trigger,
or accidentally not assign the trigger, or disable the trigger.
Roles will protect data from such cases.

To implement this approach, trigger function run on behalf of the function creator.
This poses a data security risk,
to prevent anyone else from using this function, we will block access to it.

```postgresql
-- prevents everyone from executing the trigger_timestamp function
REVOKE ALL ON ROUTINE trigger_timestamp() FROM PUBLIC;
-- allows the administrator to execute the trigger_timestamp function
GRANT ALL ON ROUTINE trigger_timestamp() TO "postgres";
```

```postgresql
-- user table with timestamps
CREATE TABLE "user"
(
    "id"       SERIAL PRIMARY KEY,
    "nickname" VARCHAR(100) NOT NULL UNIQUE
) INHERITS ("timestamp");
```

Create a user and limit his rights.

```postgresql
CREATE ROLE "test_timestamp" LOGIN;
GRANT CONNECT ON DATABASE "postgres" TO "test_timestamp";
-- give access rights to the user
-- the key point is that there is no access to editing timestamps
GRANT INSERT ("id", "nickname"), UPDATE ("id", "nickname"), SELECT ON TABLE "user" TO "test_timestamp";
```

Change current user to new user or connect to database using new user.

```postgresql
SET ROLE "test_timestamp";
```

Let's try to insert with `"created_at"` column get error.

```postgresql
INSERT INTO "user" (id, nickname, created_at)
VALUES (DEFAULT, 'max', DEFAULT);      
```

Let's try to insert without `"created_at"` column get success.

```postgresql
INSERT INTO "user" (id, nickname)
VALUES (DEFAULT, 'max');
```

## Files

- `tables/*.sql` definition parent tables `"timestamp"` `"timestamp_del"`
- [triggers/timestamp.sql](./triggers/timestamp.sql) parent table trigger
- [event_triggers/add_triggers_from_timestamp_parent_tables.sql](./event_triggers/add_triggers_from_timestamp_parent_tables.sql)
  event trigger function
- [init.sql](./init.sql) definition event trigger
- [test/*.sql](./test) test files
