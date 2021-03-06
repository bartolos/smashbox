Overview
========

This is a framework for end-to-end testing the core storage functionality of 
owncloud-based service installation. This test framework may be run interactively from a command line, perform continous testing via cron jobs or stress/load testing. It may be easily integrated in testing and QA process.

What we check:
   * sync clients in various scenarios
   * trashbin and versioning
   * sharing of files and folders
   * basic protocol checks and documentation

The goal of this is to:
   * make sure that behaviour of the system is understood and not 
     changing unintentionally
   * reproduce difficult bugs more easily
   * a testcase is better way of reporting and documenting bugs 
     or undesider behaviour to the developers
   * provide a broad test coverage given a large number of setups and platforms

If you think you see a bug - write a test-case and let others
reproduce it on their systems.

This is work in progress. 

Project tree
============

General layout:

<pre>

   smashbox
   ├── bin/
   │   └── smash*                               : main test driver + other utilities for direct shell use
   ├── etc/				
   │   └── smashbox.conf                        : configuration file - this is also the default configuration for smashbox/bin utilities and for test-cases
   ├── lib/                                     : main collection of test-cases
   │   ├── test_nplusone.py			
   │   └── ...  			        
   ├── protocol/                                : sync protocol tests and documentation
   ├── python/                                  : implementation of tools and API library for tests
   │   └── smashbox/utilities                   : here is the utilities used directly in the test-cases
   ├── server/                                  : server-side procedures used in the tests
   ├── client/                                  : owncloud client helpers 
   │   └── compile-owncloud-sync-client*        : 
   └── README                                   : this file
   
</pre>

Installation
============

Note: Currently this framework works on Unix-like systems only. Windows port is needed.

Clone git repository into your local ``smashbox`` directory.

Copy the etc/smashbox.conf.template into etc/smashbox.conf

Note: a helper shell script, makeconfig, has been added to the etc directory. 
Edit this file to make some of the more common configuration changes and then run the script.  
This will create a local smashbox.conf file.

Set the oc_sync_cmd to the location of the owncloud command-line
client (see client/compile-owncloud-sync-client if you don't have one
yet compiled).

Set the oc_account_password.

Otherwise the default configuration should work out-of-the-box if you
run the smashbox tests locally on the owncloud server. You should try
that first (on the TEST server instance).

Support has been added for the provisioning API which creates a dependency on the pyocclient repo.

To install the library, run the following after checking out your branch:

pip install -r requirements.txt

If you want to use a local copy of pyocclient, you can add the following to your shell environment:

export PYTHONPATH=/local/path/to/pyocclient/repo/branch

and clone git repository into your local ``pyocclient`` directory.

First test runs
===============

When you run a test several workers (clients) are started in parallel
locally and access owncloud server according to the test-case
scenario. The test-case specifies which actions happen simultaneously.

Examples:

    # help on all available options
    bin/smash --help

    # basic test
    bin/smash lib/test_basicSync.py
    
    # run a test with different paremeters
    bin/smash -o nplusone_nfiles=10 lib/test_nplusone.py
    
    # run all tests - print summaries only
    bin/smash --quiet lib/test_*.py

You will find main log files in ~/smashdir/log* and all temporary files and detailed logs for each test-case in ~/smashdir/<test-case>

Monitoring integration
=======================

Currently, monitoring module is supporting `local` and `prometheus` endpoints. Prometheus endpoint can be used in integration with Jenkins.

By default, two values are prepared for export, 'total_duration' and 'number_of_queries', however one can embed inside the test their custom variables using e.g. `commit_to_monitoring("download_duration",time1-time0)` inside `lib/test_nplusone.py` test.

**NOTE: To enable checking number of queries, one need to set `oc_check_diagnostic_log = True` in the `smashbox.conf` file**

**NOTE: To enable diagnostics in SUMMARY level on the server one need to go to the server directory e.g. `/var/www/owncloud` and:**

```
git clone https://github.com/owncloud/diagnostics apps/diagnostics
sudo -u www-data php occ app:enable diagnostics
sudo -u www-data php occ config:system:set --value true debug
sudo -u www-data php occ config:app:set --value 1 diagnostics diagnosticLogLevel
```

**Export to local monitor example:**

Executing

```
bin/smash -t 1 -o monitoring_type=local lib/test_nplusone.py
```

will execute index `1` of `test_nplusone` test and adding option flag `-o monitoring_type=local` will result in the below output if test has been completed successfully

```
download_duration 0.750847816467
upload_duration 1.4001121521
returncode 0
elapsed 6.87230300903
```

or below in case of failure

```
returncode 2
elapsed 7.0446870327
```

**Export to prometheus with jenkins example:**

Executing

```
bin/smash -t 1 -o monitoring_type=prometheus -o endpoint=http://localhost:9091/metrics/job/jenkins/instance/smashbox -o duration_label=jenkins_smashbox_test_duration -o queries_label=jenkins_smashbox_db_queries -o owncloud=daily-master -o client=2.3.1 -o suite=nplusonet1 -o build=test_build1 lib/test_nplusone.py
```

will result in:
 * pushing the monitoring points to the Prometheus endpoint `http://localhost:9091/metrics/job/jenkins/instance/smashbox`
 * Adding flags `-o duration_label=jenkins_smashbox_test_duration` and `-o queries_label=jenkins_smashbox_db_queries` will cause default results 'total_duration' and 'number_of_queries' to be exported to Prometheus.
 * Additional flags `-o owncloud=daily-master`, `-o client=2.3.1`, `-o suite=nplusonet1`, `-o build=test_build1` can be used in order to distinguish smashbox runs

or below in case of failure to push to monitoring

`curl: (7) Failed to connect to localhost port 9091: Connection refused`

**Adding custom monitoring endpoint:**

One can add their own monitoring endpoint by [adding new option](python/smashbox/utilities/monitoring.py) in `push_to_monitoring`. You can test your custom test (as in [test_nplusone](lib/test_nplusone.py)) and monitoring endpoint setting flag
`-o monitoring_type=MY_CUSTOM_MONITORING_TYPE` e.g. `-o monitoring_type=local`


Different client/server
=======================

Make sure you can passwordlessly ssh to the server node (only for some admin tasks like creating accounts)
You will need to set oc_server, oc_server_shell_cmd. 

If you don't keep the same path on the server and the client to the smashbox git repository clone then you will need to set oc_server_tools_path.

As of version x.x, the provisioning API is used for user management on the server so this is no longer needed.

Adding new tests
================

Simply add new tests to smashbox/lib. If you have specific tests which are not generally applicable or which belong to the same functional category it is best to store them in a subdirectory, e.g. smashbox/lib/oc-tests.

If you need to add new utilities then add a module in smashbox/python/smashbox/utilities.


Design criteria for this testing software
=========================================

  - test scripts with minimal code clutter
  - possible to run individual test scripts or the whole suite at once
  - convenient run environment for systematic and ad-hoc testing
  - easy and flexible configuration
  - easy to add and run tests in an additional lib
  - possibility to extend with cluster mode (distributed workers)


Test configuration details
==========================

Configuration may be set globally in smashbox/etc/smashbox.conf,
passed as a command line option to commands or hardcoded in the code
of an individual test. This is also the priority order - whatever is
defined last wins.

In the future we would like to add other possibilities
(lib/smashbox.conf, $SMASHBOX_CONF file if defined)

Local working directories keep temporary files, local sync folders, etc. General structure (some elements of the path may be ommited, others may be transformed)::

     <smashdir>/<rundir>/<testname>

Server test accounts follow this general naming scheme (some elements may be ommited, others may be transformed) ::

    smash-<runid>-<collection>-<testname>
   

Organization of test directories
----------------

Consider running an simple test::

    smash smashbox/lib/test_nplusone.py

If workdir_runid_enabled option is enabled then local working directory will be everytime different (and unique)::
 
    <runbasedir>/test_nplusone-<runid>

The format of <runid> identifier is defined by the runid option.

Otherwise the local working directory will be the same (and cleaned-up before running the test)::

    <runbasedir>/test_nplusone

If oc_account_runid_enabled is enabled then the test account on the server will be everytime different (and unique)::

    smash-nplusone-<runid>

Otherwsie the test account on the server will be everytime the same (and will be cleaned-up before running the test)::

    smash-nplusone

The account_cleanup_procedure defines how the account is cleaned-up before running the test. These procedures are defined in smashbox/python/smashbox.


