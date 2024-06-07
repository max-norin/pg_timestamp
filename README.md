# pg_timestamp

100% works on PostgreSQL version 16, I didn't check the rest.
If you have any information that works on earlier versions, please let me know.

> An extension for PostgreSQL that allows you to create tables
> with timestamps (created_at, updated_at, deleted_at) using table inheritance.

Note: when deleting inheritance by the command
`ALTER TABLE public.new_users NO INHERIT public.users;`,
no additional actions will occur. The table will have
the same columns, constraints, and triggers as in inheritance.
Including automatically inherited `CHECK` and `NOT NULL` constraints.

[README in Russian](./README.ru.md)

# Installation

For version 2.0 to work, you will need to add
[pg_full_inherit](https://github.com/max-norin/pg_full_inherit) extension
to a PostgreSQL application.
This extension allows you to do full table inheritance, i
ncluding automatic inheritance of triggers, which is necessary
and mandatory for the current extension to work.
In earlier versions we used our own method for automatically adding
triggers to inherited tables.

## Classic

Download `pg_timestamp--2.0.sql` and `pg_timestamp.control` files
from [dist](./dist) and move them to the `extension`
folder of the PostgreSQL application.
For windows, the folder can be located in
`C:\Program Files\PostgreSQL\16\share\extension`.
Next, run the following commands.

Create a new schema for convenience.

```sql
CREATE SCHEMA "abstract";
ALTER ROLE "postgres" SET search_path TO "public", "abstract";
```

Install the extension.

```sql
CREATE EXTENSION "pg_timestamp"
    SCHEMA "abstract"
    VERSION '2.0';
```

[Learn more about an extension and control file](https://www.sql.org/docs/current/extend-extensions.html)

## Workaround

If you can't add the extension to PostgreSQL, then there is another option.
Copy the contents of `pg_timestamp--2.0.sql` file from [dist](./dist) to a text editor.
Replace the expression `@extschema@` with a schema
to which the necessary functions will be added, for example `abstract`.
Copy it to the PostgreSQL console and run it.

# Usage

The extension has two parent tables`"timestamp"` and `"timestamp_del"`.

## `"timestamp"` table

The `"timestamp"` table has `"created_at"`, `"updated_at"` columns and a trigger
that updates these columns.
You can create a new child table as follows.

```sql
CREATE TABLE "user"
(
    "id"       SERIAL PRIMARY KEY,
    "nickname" VARCHAR(100) NOT NULL UNIQUE
) INHERITS ("abstract"."timestamp");
```

Event trigger from
[pg_full_inherit](https://github.com/max-norin/pg_full_inherit) extension
will recognize that a table is being created
that inherits from the `"timestamp"` table and
will automatically add a trigger.

## `"timestamp_del"` table

The table `"timestamp_del"` in addition to `"timestamp"` table has `"deleted_at"` column.
You can create a new child table as follows.

```sql
CREATE TABLE "user"
(
    "id"       SERIAL PRIMARY KEY,
    "nickname" VARCHAR(100) NOT NULL UNIQUE
) INHERITS ("abstract"."timestamp_del");
```

# Recommended use

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

```sql
-- prevents everyone from executing the trigger_timestamp function
REVOKE ALL ON ROUTINE trigger_timestamp() FROM PUBLIC;
-- allows the administrator to execute the trigger_timestamp function
GRANT ALL ON ROUTINE trigger_timestamp() TO "postgres";
```

```sql
-- user table with timestamps
CREATE TABLE "user"
(
    "id"       SERIAL PRIMARY KEY,
    "nickname" VARCHAR(100) NOT NULL UNIQUE
) INHERITS ("timestamp");
```

Create a user and limit his rights.

```sql
CREATE ROLE "test_timestamp" LOGIN;
GRANT CONNECT ON DATABASE "postgres" TO "test_timestamp";
-- give access rights to the user
-- the key point is that there is no access to editing timestamps
GRANT INSERT ("id", "nickname"), UPDATE ("id", "nickname"), SELECT ON TABLE "user" TO "test_timestamp";
```

Change current user to new user or connect to database using new user.

```sql
SET ROLE "test_timestamp";
```

Let's try to insert with `"created_at"` column get error.

```sql
INSERT INTO "user" (id, nickname, created_at)
VALUES (DEFAULT, 'max', DEFAULT);      
```

Let's try to insert without `"created_at"` column get success.

```sql
INSERT INTO "user" (id, nickname)
VALUES (DEFAULT, 'max');
```
