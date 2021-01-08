# Johns Hopkins Catalyst

Catalyst is the Johns Hopkins Libraries discovery system.
It is an extension of the Blacklight Project

## Development

### Setting up a local solr instance

### Settup local mysql

### Running Catalyst

We currently have no development or test server available.

```
chruby ruby-2.2.2
CATALYST_SOLR_URL=http://localhost:8983/solr/#/blacklight-solr/select? bundle exec rails server
```

## Google Analytics

## Deployment

Catalyst uses capistrano 2 to deploy to the live server.

You will have to add your ssh public key to the catalyst@catalyst.library.jhu.edu
and catalyst@catsolrmaster.library.jhu.edu servers.

Capistrano ssh also uses keyforwarding so you will have to add the following in your .ssh/config file
```
Host *.library.jhu.edu
  ForwardAgent yes
```

This also tags the code in git.
```
bundle exec cap deploy
```
If you want to rollback to a particular verion you can 
```
bundle exec cap deploy:rollback
```

To rollback to a particular version
```
cap deploy:rollback -s previous_release=/opt/umlaut_jh/releases/20150630175555
```

The deploy process will check that local code has been commited,
and no changes require pulling. To skip this check you can pass 
the **skip_guard_upstream** switch
```
bundle exec cap deploy -s skip_guard_upstream=true
```

