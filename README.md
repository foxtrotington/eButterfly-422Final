# eButterfly-422Final

Pipeline optimized for UA HPC to generate Species Diversity Maps for 601 species of butterfly observations obtained from eButterfly. SDMs generated for each species, using three different species diversity algorithms (CTA, GLM, RF), in combination of three different background replicate values (1, 10, 50). Utilizes PBS Job Arrays for parallelization. 

Quick Start Guide:

    $ git clone git@github.com:foxtrotington/eButterfly-422Final.git

    $ cd eButterfly-422Final.git/scripts

Edit get_sdm.sh to include the correct PBS group list and your netid for email notification.

    $ vi get_sdm.sh

    $ cd ..

    $ vi settings.sh

Edit the OUT directory for SDM output storage. 

    $ ./submit

-------------------------------------------------------------------------------------------------------

HPC Pipeline Details

THis HPC pipeline is parallelized using PBS Job Arrays. Data is passed to each individual job through subsetted "data lists" (as found in data/subsets/lists). The -J parameter passed to qsub indicated the number of jobs to run. The PBS_ARRAY_INDEX is used to target a specific list for each individual job. Each list contains 6 data files to ensure jobs can complete before walltime limit is reached. This particular workflow is designed to execute correctly following quick start instructions. Any modifications to the workflow would require editing the list files found within data/subsets as well as changing the -J parameter found in submit.sh.

## Data

<p>There are various tasks that need to be accomplished before the ebutterfly data is prepped and ready for SDM consumption. The following are different SQL commands that will show you what data isn't suitable for SDM consumption. You can create a quarantine table and append <code>INSERT INTO quarantine</code> to the commmands to create copies of the bad data in that table.</p>

<p style="margin-top: 15px;">It's also advised that a permanent ebutterfly table be created in order to use delete commands to get rid of bad data after insertion into the qurantine table.</p>

**Note:** The create steps are included in `data/data_empty_create.txt` but are shown here separately in case you only want to see or use specific commands.

### Table of Contents
<ol>
	<li>
    	<a href="#data-prep">Data Prepping</a>
    	<ul>
            <li><a href="#create-sdm-funct">Create generate_sdm_table Function</a></li>
	        <li><a href="#create-ebutterfly">Create ebutterfly_sdm_table</a></li>
	        <li><a href="#create-taxon_sciname-table">Create TaxonId and Scientific Name Table</a></li>
    	</ul>
    </li>
    <li>
    	<a href="#data-cleaning">Data Cleaning</a>
        <ul>
            <li><a href="#bad-lat_lng">Non-decimal and Bad Lat/Lng Formats</a></li>
	        <li><a href="#missing-year_month">Missing Year or Month</a></li>
	        <li><a href="#missing-sciname">Missing Scientific Name</a></li>
        </ul>
    </li>
</ol>

### Data Prepping
<p id="create-sdm-funct">Create function that will be used to generate the sdm table from the ebutterfly SQL dump.</p>

```sql
CREATE OR REPLACE FUNCTION generate_sdm_table(
	)
    RETURNS TABLE(observation_id integer, species_id integer, latin_name text, year integer, month integer, latitude character varying, longitude character varying) 
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    ROWS 1000
AS $BODY$

BEGIN 
RETURN QUERY 
	WITH interestedObservations
    AS (
        SELECT O.observation_id, O.checklist_id, O.species_id
        FROM eb_butterflies.observations AS O 
        JOIN eb_central.idconfidences AS IC
        ON O.idconfidence_id=IC.idconfidence_id
        JOIN eb_central.lifestages AS LS
        ON O.lifestage_id=LS.lifestage_id
        JOIN eb_central.observationstatuses AS OS
        ON O.observationstatus_id=OS.status_id
        WHERE 
        idconfidence='High' AND
        lifestage='Adult' AND
        (observation_status='Vetted' OR observation_status='Pending')
    ), 
    onlyOnesInSpeciesTable
    AS (
    	SELECT O.observation_id, O.checklist_id, S.species_id, S.latin_name 
        FROM interestedObservations AS O
        JOIN eb_butterflies.species AS S
        ON O.species_id=S.species_id
    ),
    grabYearMonthAndSiteId
    AS (
    	SELECT O.observation_id, O.species_id, O.latin_name, C.site_id, C.year, C.month
        FROM onlyOnesInSpeciesTable AS O 
        JOIN eb_central.checklists AS C 
        ON O.checklist_id=C.checklist_id
    ),
    grabLatLng 
    AS (
        SELECT O.observation_id, O.species_id, O.latin_name, C.latitude, C.longitude, O.year, O.month
        FROM grabYearMonthAndSiteId AS O 
        JOIN eb_central.sites AS C 
        ON O.site_id=C.site_id
    ) 
    SELECT O.observation_id, 
    	   O.species_id, 
           CAST(O.latin_name as text), 
           CAST(O.year AS integer), 
           CAST(O.month as integer), 
           O.latitude, 
           O.longitude 
           FROM grabLatLng AS O;
END;
```

<p id="create-ebutterfly">Create table to house ebutterfly data from generate_sdm_table() function.</p>

```sql
CREATE TABLE ebutterfly_sdm_table
(
    observation_id integer,
    species_id integer,
    latin_name text COLLATE pg_catalog."default",
    year integer,
    month integer,
    latitude character varying(256) COLLATE pg_catalog."default",
    longitude character varying(256) COLLATE pg_catalog."default"
);
```

<p id="create-taxon_sciname-table">Create table to house taxon ids and scientific names for easy joins and latin_name updates with ebutterfly table.</p>

```sql 
CREATE TABLE inat_species
(
    taxonid integer,
    scientificname text COLLATE pg_catalog."default"
);
```


### Data Cleaning
<p>You can decide to change the table name to <code>ebutterfly_sdm_table</code> if you used the create table command from above and inserted data into it. If not, use these as a way to see bad data and make decisions from there.<p>

<p id="bad-lat_lng">Non-decimal and bad lat/lng formats</p>

```sql
SELECT * FROM generate_sdm_table()
WHERE latitude NOT SIMILAR TO '-?[0-9]+.[0-9]+' 
AND longitude NOT SIMILAR TO '-?[0-9]+.[0-9]+';
```


<p id="missing-year_month">Missing year or month</p>

```sql
SELECT * FROM generate_sdm_table() WHERE year IS NULL OR month IS NULL;
```


<p id="missing-sciname">Missing Scientific Name</p>

```sql
SELECT * FROM generate_sdm_table() WHERE latin_name = '';
```
<p id="with-taxonid">Final Join With Scientific Name from Jeff's List</p>

```sql
SELECT observation_id, species_id, latin_name, year, month, latitude, longitude FROM generate_sdm_table() 
AS G JOIN inat_species AS I 
ON G.latin_name=I.scientificname
```


