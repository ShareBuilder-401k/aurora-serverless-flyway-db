# Aurora Serverless Flyway DB
# Database Documentation

Created at: 2020-05-11T04:25:38.533Z
Server version: PostgreSQL 12.2 on x86_64-pc-linux-musl, compiled by gcc (Alpine 9.2.0) 9.2.0, 64-bit
## Schema: public

### Tables

#### public.flyway_schema_history

column | comment | type | length | default | constraints | values
--- | --- | --- | --- | --- | --- | ---
**installed_rank** _(pk)_ |  | integer |  |  | NOT NULL | 
version |  | character varying | 50 |  |  | 
description |  | character varying | 200 |  | NOT NULL | 
type |  | character varying | 20 |  | NOT NULL | 
script |  | character varying | 1000 |  | NOT NULL | 
checksum |  | integer |  |  |  | 
installed_by |  | character varying | 100 |  | NOT NULL | 
installed_on |  | timestamp without time zone |  | now() | NOT NULL | 
execution_time |  | integer |  |  | NOT NULL | 
success |  | boolean |  |  | NOT NULL | 

#### public.sample

column | comment | type | length | default | constraints | values
--- | --- | --- | --- | --- | --- | ---
**id** _(pk)_ |  | integer |  | nextval('sample_id_seq'::regclass) | NOT NULL | 
message |  | character varying | 255 |  |  | 
