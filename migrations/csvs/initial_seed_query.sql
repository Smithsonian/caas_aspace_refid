-- Queries used to generate initial seed csvs for migration 2
-- Exported csv will contain:
--    resource_id (INT) - Self explanatory
--    maxlen_ref_id (INT) - The length of the longest existing refid (used to filter/optimize subsequent query)
--    max_ref_id (varchar(255)) - The current maximum ref_id (the full string of the ref_id)
--    next_refid (INT) - The next_refid (increment/integer only) to be seeded into the db

CREATE TEMPORARY TABLE temp_max_ref_id(resource_id 	INT, maxlen_ref_id INT, max_ref_id varchar(255), next_refid INT);

-- Grab ids of resources with archival objects
INSERT INTO temp_max_ref_id(resource_id)
SELECT
    r.id
FROM
    resource r
WHERE
    EXISTS( SELECT 
            *
        FROM
            archival_object
        WHERE
            root_record_id = r.id);

-- Calculate the longest existing ref_id for each resource
UPDATE temp_max_ref_id tmri
SET 
    maxlen_ref_id = (SELECT 
            MAX(LENGTH(ao.ref_id))
        FROM
            archival_object ao
        WHERE
            ao.root_record_id = tmri.resource_id); 

-- Find the current max ref_id for each resource by looking at any ao's with the longest existing ref_ids
UPDATE temp_max_ref_id tmri 
SET 
    tmri.max_ref_id = (SELECT 
            MAX(ao.ref_id)
        FROM
            archival_object ao
        WHERE
            tmri.resource_id = ao.root_record_id
                AND LENGTH(ao.ref_id) = tmri.maxlen_ref_id);

-- Add the `next_refid` column needed by migration 2.  This represents the next integer/increment after the currently existing max refid
UPDATE temp_max_ref_id tmri 
SET 
    tmri.next_refid = (SELECT 
            CAST(SUBSTRING_INDEX(tmri.max_ref_id, '_ref', - 1)
                    AS UNSIGNED) + 1)
WHERE
	1 = 1;

-- Grab just the values we need from this temp table
SELECT resource_id, next_refid FROM temp_max_ref_id;

-- Clean up after ourselves
DROP TABLE temp_max_ref_id;