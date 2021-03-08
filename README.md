# Johns Hopkins Catalyst ( Blacklight Library Catalog )
![CI Workflow](https://github.com/jhu-library-applications/catalyst-blacklight/workflows/CI/badge.svg?branch=main)

Catalyst is the Johns Hopkins Libraries catalog.

It is an extention of the Blacklight project which uses Solr as a central index.

This project is managed by the Library Applications, with production support (monitoring, backup, recovery, security) provided by Library Operations.

Catlayst also contains important subprojects:

- horizon-holding-info-servlet: runs in jetty, connects to Horizon DB, and looks up borrower info
- traject ( uses traject_horizon ) connects to Horizon DB and manages the Solr index

## Components

### Web Service for Borrower and Holdings Info from Horizon.
https://github.com/jhu-sheridan-libraries/horizon-holding-info-servlet/blob/master/README.md

### Traject
Indexes catalog records from Horizon to build the Solr index
https://github.com/jhu-sheridan-libraries/catalyst-traject

### Course Reserves
There are two parts to this feature.
1. Loader is in its own project
https://github.com/jhu-sheridan-libraries/catalyst-pull-reserves

2. Display of reserves info is controlled in this project
https://github.com/jhu-library-applications/catalyst-blacklight/blob/master/app/controllers/reserves_controller.rb

### Virtual Shelf Browse
This feature is a gem located at
https://github.com/jhu-sheridan-libraries/rails_stackview

### My Account
This is a home-grown feature that includes a user login and various other functionality
- Login
https://github.com/jhu-library-applications/catalyst-blacklight/blob/master/app/controllers/user_sessions_controller.rb
- Other functionality
https://github.com/jhu-library-applications/catalyst-blacklight/blob/master/app/controllers/users_controller.rb

Note: My Account uses Horizon HIP service to handle requests, renewals, holds, etc.
https://github.com/jhu-library-applications/catalyst-blacklight/blob/master/lib/hip_pilot.rb

## Development

Our internal Confluence wiki has [instructions for setting up a local development environment](https://jhulibraries.atlassian.net/wiki/spaces/CATALYST/pages/31555846/HOWTO+Local+Sandbox+Setup).

## Deployment

### Deploying With Capistrano

Catalyst can be deployed with either `ansible` or `capistrano`. `ansible` should be used
for creating the initial virtual machines and setting up system requirements.

To see information about deploying with ansible view the [README for catalyst-ansible](https://github.com/jhu-library-applications/catalyst-ansible/).

`capistrano` should be used for deployments when the underlying software on the server does not need to
change.

Using capistrano requires that your SSH keys have been added to the server you want to
deploy to. It also requires that you add the key you use to login to our servers
and the key that you use with GitHub to your SSH agent. You can do that using
the `ssh-add` command (your keys may not have the same names):

```
ssh-add ~/.ssh/id_rsa
ssh-add ~/.ssh/jhu_ssh_key
```

GitHub has [documentation for key forwarding](https://docs.github.com/en/developers/overview/using-ssh-agent-forwarding) that describes how
this makes the deployment process easier.

Begin by adding a section in your `~/.ssh/config` file for the server:

```
# --- Catalyst ---
Host catalyst catalyst.library.jhu.edu
        Hostname catalyst.library.jhu.edu
        User yourjhedhere
        ForwardAgent yes
# ----------------------------

# --- Catalyst Staging ---
Host catalyst-stage catalyst-stage.library.jhu.edu
        Hostname catalyst-stage.library.jhu.edu
        User yourjhedhere
        ForwardAgent yes
# ----------------------------

# --- Catalyst Test ---
Host catalyst-test catalyst-test.library.jhu.edu
        Hostname catalyst-test.library.jhu.edu
        ForwardAgent yes
        User yourjhedhere
# ----------------------------
```

To test that this is working you can SSH into `catalyst-test` and
run `ssh git@github.com` if you get a success message then key
forwarding has been setup correctly.

After that you can deploy from local machine using the following
command:

```
CAP_USER=yourjhedid BRANCH=v2.3.5 bundle exec cap test deploy
```

The environment variables that proceed the command need to be
present. `CAP_USER` is your JHED and `BRANCH` is the git branch
that you want to deploy.

#### Common Issues When Deploying

Your user must be in the `catalyst` group on the server. To
see if you are in the group after logging in with SSH:

`groups`

That should list `catalyst` among your groups. If you are not
in the group and you have `sudo` permissions on the server you can
add yourself:

```
sudo usermod -a -G catalyst yourusernamehere
```

If you do not have `sudo` permisisons on the server ask someone in
LAG or Ops to add you to the group.

If you get a permission denied error when deploying this can
often be solved by running these commands to make sure that
the deploy directory is owned by the catalyst group and members
of that group have read and write permissions:

```
sudo chown -R catalyst:catalyst /opt/catalyst
sudo chmod -R g+w /opt/catalyst
```

[Additional information about deployment](https://jhulibraries.atlassian.net/wiki/spaces/CATALYST/pages/825655305/Deploying+Catalyst+with+Capistrano+and+Ansible)
can be found on Confluence.

#### Horizon upgrade

During Horizon upgrades, we need to disable patron account features, while allowing patrons to use other catalyst features.

In config/initializers/disable_hip.rb, set

```
JHConfig.params[:disable_hip] = true
```

In the same file, update the message displayed to users:

```
JHConfig.params[:disable_hip_message]
```
