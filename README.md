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

