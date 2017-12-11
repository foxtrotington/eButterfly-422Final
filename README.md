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

## Data Cleaning

<div>There are various tasks that need to be accomplished before the ebutterfly data is prepped and ready for SDM consumption. The following are different SQL commands that will show you what data isn't suitable for SDM consumption. You can create a quarantine table and append <code>INSERT INTO quarantine</code> to the commmands to create copies of the bad data in that table.</div>

<div style="margin-top: 15px;">It's also advised that a permanent ebutterfly table be created in order to use delete commands to get rid of bad data after insertion into the qurantine table. </div>

### Table of Contents
<ol>
	<li><a href="#bad-lat_lng">Non-decimal and Bad Lat/Lng Formats</a></li>
	<li><a href="#missing-year_month">Missing Year or Month</a></li>
	<li><a href="#missing-sciname">Missing Scientific Name</a></li>
</ol>

<b id="bad-lat_lng">Non-decimal and bad lat/lng formats</b>

```sql
SELECT * FROM generate_sdm_table()
WHERE latitude NOT SIMILAR TO '-?[0-9]+.[0-9]+' 
AND longitude NOT SIMILAR TO '-?[0-9]+.[0-9]+'
```
<hr />

<b id="missing-year_month">Missing year or month</b>

```sql
SELECT * FROM generate_sdm_table() WHERE year IS NULL OR month IS NULL
```
<hr />

<b id="missing-sciname">Missing Scientific Name</b>

```sql
SELECT * FROM generate_sdm_table() WHERE latin_name = ''
```


