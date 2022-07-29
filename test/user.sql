CREATE TABLE "user" (
                        "id" SERIAL PRIMARY KEY,
                        "nickname" VARCHAR(100) NOT NULL UNIQUE
)
    INHERITS (
              "timestamp_del"
        );

