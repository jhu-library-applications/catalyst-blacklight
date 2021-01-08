# Johns Hopkins Blacklight solr configuration

Solr is used by catalyst (blacklight_jh).
We have the following solr servers which are each configured differntly and are on ageing infrastructure.  This is an attempt to capture the current server configuration and function, so we can replace it with more consitant and automated infrastructure. 

- catsolrmaster.library.jhu.edu (Production)
- catsolrslave.library.jhu.edu  (Production)
- solr03.mse.jhu.edu            (Demo, Development)
- blacklight.library.jhu.edu    (Development)

This solr configuration is on multiple servers

## catsolrmaster (prod) tomcat6
This is not a JHED enable server. 

The master solr index runs every night, it indexes horizon, and other sources of data.
(all other solr indexes point to this for replication).

TODO Determine the impact on running the indexing during the week.
TODO Ensure the server comes back after a restart with all services started and in a ready state

This server has a impressive uptime of > 270 days. But suffered some resent downtime.
Consists of :  

  - centos ?? 
  - tomcat 6
    - path: /usr/local/tomcat6
    -
  - java 1.7.0_25
  - solrs 
    - solr4master  ( unknown )
    - solr4slave   ( unknown)
    - solr_indexer ( production master)
    	- production: master_prod
    	- path:  /opt/solr/solr_indexer/master_prod 
	- git: THIS PROJECT
        - logs: 
	- restart: sudo ?? 
	- cron ( user = catalyst ) indexed every night
	- http://catsolrmaster.library.jhu.edu:8984/solr/#/master_prod 
    - solr_searcher ( unknown )
   
The indexing process itself is run by the catalyst user 
    - ruby - jruby-1.7.4
    - code /opt/catalyst/app/current/traject
    - cron managed in the catalyst project by capistrano
    - 30 18 * * * /opt/catalyst/app/releases/20170407140317/bin/cronmail -x "cd /opt/catalyst/app/releases/20170407140317/traject && SHELL=/bin/bash PATH=$PATH:/usr/local/bin RAILS_ENV=production chruby-exec jruby -- bundle exec rake horizon:mass_index" -s "Catalyst (traject) mass reindex" -e "fsadiq1@jhu.edu,jwang40@jhu.edu,gara@jhu.edu"
   

## catsolrmater (slave) msel-solr02.mse.jhu.edu 

Login via JHED ssh restricted to LAG office machines. 
 - centos 5.11
 - tomcat5.5.23 (rpm)
   - user: tomcat
 - java  1.6.0_37
 - memory 32G
 - solr
   - path /opt/solr_searcher
   -  
