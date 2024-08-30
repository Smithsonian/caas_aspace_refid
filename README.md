# CAAS Aspace Ref_id Plugin

A plugin used to auto-increment archival object `ref_id`s per Smithsonian guidelines.  Namely:

```
[EADID]_ref[auto-incrementing number]
```
or
```
NMAH.AC.0001_ref1
```

If, for some reason, the system is unable to auto-increment a refid value for a given archival object, the refid will fall back to using a datestamp to ensure refid uniqueness (specifically, `DateTime.now.strftime('%Q')`).  This is the same fallback used in the legacy refid plugin.  The resulting refids will look something like:
```
NMAH.AC.0001_ref1726174601021
```

## Data Model

The initial migration for this plugin adds two new tables to the ArchivesSpace database.  `caas_aspace_refid_schema_info` tracks the current schema version of the plugin, whereas `caas_aspace_refid` stores a listing of resource records (by resource id) and its last assigned refid (in `next_refid`).

## Seeding Data

The second migration `migrations/002_seed_initial_values.rb` will do the work of seeding the initial data required by the plugin.  To prepare for this migration, you will need a csv in the following format:

```
resource, next_ref_id
<my resource number>, <my last used refid>
7572, 621
43363, 10
```

You can name this file whatever you would like, including the date is generally a good idea.  While it can be saved anywhere in the plugin directory, storing it in `migrations/csvs` will make it simpler to call the file when the migration is run.

To run the migration and seed this data:

1. Stop ArchivesSpace
2. Run migrations:
    ```
    scripts/setup-database.sh
    ```
3. When prompted, type the path to your csv and hit 'return':
    ```
    [java] ********* What is the path to your csv file (relative to the `caas_aspace_refid/migrations/csvs` directory)? *********
    20240912examplecsv.csv
    ```
    Alternatively, you may set an environment variable holding the path to your csv file prior to running the migration, like so:
    ```
    export REFID_SEED_FILE='20240912examplecsv.csv'
    scripts/setup-database.sh
    ```
    If this is set, you will not be prompted to provide a path to your csv.  If using this option, remember to unset the environment variable after the migration has completed:
    ```
    unset REFID_SEED_FILE
    ```
4. If an error is encountered during the migration, a warning will be displayed.  Type either 'c' to continue and ignore that error, or 'q' to quit the migration.  (Additional information about these options is in "Migration Error Handling" below)
    ```
    [java] ERROR: Cannot create next refid record for resource 1. No resource record with that id exists.
    [java] ********* What would you like to do? *********
    [java] (c)ontinue anyway (the above error will have to be addressed separately in a future migration, db update, etc.)
    [java] (q)uit migration without making any changes
    ```
5. Once the migration has completed, embedded logs will document the changes made during the migration:
    ```
    INFO: Preparing to update next refid for resource 14.
    INFO: Preparing to create new next refid for resource 17.
    INFO: The following 2 records were successfully created/updated:
    {:id=>2, :lock_version=>0, :json_schema_version=>1, :resource_id=>14, :next_refid=>16745, :created_by=>nil, :last_modified_by=>nil, :create_time=>2024-09-12 20:42:32 UTC, :system_mtime=>2024-09-12 20:42:32 UTC, :user_mtime=>2024-09-12 20:42:32 UTC}
    {:id=>3, :lock_version=>0, :json_schema_version=>1, :resource_id=>17, :next_refid=>122, :created_by=>nil, :last_modified_by=>nil, :create_time=>2024-09-12 20:42:32 UTC, :system_mtime=>2024-09-12 20:42:32 UTC, :user_mtime=>2024-09-12 20:42:32 UTC} 
    ```

### Migration Error Handling

If an error is encountered during a data-altering migration (e.g. seeding initial refid values), two options will be provided:

1. Typing 'c' to continue a migration will ignore the problem record(s), but otherwise run through to completion.  Issues identified during the migration will have to be handled later - through a subsequent migration (preferred), regenerating/generating refids in the application UI, or thorugh a direct database update (not preferred).  Since the initial seeding migration will have completed, the migration schema version will increment forward and this initial migration will not be able to be run a second time.
2. Typing 'q' will halt the migration and return the db to the state it was in prior to attempting the migration.  No rows will be added to the `caas_aspace_refid` table and the schema version will not change.  After fixing the issues identified within your csv, you can attempt to run the migration again.  This is the preferred method of seeding data.

## Updating Refids through the UI

Should one or a small number of refids need to be regenerated in the UI, a "Regenerate Ref ID?" checkbox has been added to the archival object form.  This checkbox is currently only visible to system administrators.  When checked, the same logic that autogenerates refids on new records will be called on the save of an existing archival object record.  Since this logic concatenates a resource's EADID alongside a +1 of the refid stored in the `caas_aspace_refid` table for that resource, this manual process can be useful in the case where an EADID has changed and/or if an unexpected refid collision is anticipated.

## Running Tests

From archivesspace project directory:
`./build/run backend:test -Dspec="../../plugins/caas_aspace_refid"`
