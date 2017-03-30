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

Important integration tests
===============

The below tests are being used in [Jenkins/Smashbox Integration Dashboard ](https://jenkins.owncloud.org/view/smashbox/)

[BASH script with all below tests](integration_test_cmds.sh)

**Note: Please refer to sections `Installation` and `First test runs` for more details. Mentioned below [index] refers to variable in the flag `-t [index]`**

 * [Basic Sync and Conflicts ](lib/test_basicSync.py)
    - basicSync_filesizeKB from 1kB to 50MB (normal and chunked files sync)
    - basicSync_rmLocalStateDB removing local database in the test (index 0-3) or not (index 4-7)

 * [Concurrently removing directory while files are being added ](lib/test_concurrentDirRemove.py)
    - Currently only checks for corrupted files in the outcome (TODO: extend test with expected outcome)
    - Removing the directory while a large file is chunk-uploaded (index 0)
    - Removing the directory while lots of smaller files are uploaded (index 1)
    - Removing the directory before files are uploaded (index 2)

 * [Resharing ](lib/oc-test/test_reshareDir.py)
    - Share directory with receiver and receiver reshares one of the files with another user

 * [Directory Sharing between users ](lib/oc-test/test_shareDir.py)
    - Tests various sharing actions between users

 * [Files Sharing between users ](lib/oc-test/test_shareFile.py)
    - Tests various sharing actions between users

 * [Files Sharing between users and groups ](lib/oc-test/test_shareGroup.py)
    - Tests various sharing actions between users and groups

 * [Files Sharing by link ](lib/oc-test/test_shareLink.py)
    - Tests various sharing actions with links

 * [Ensures correct behaviour having different permissions ](lib/oc-test/test_sharePermissions.py)
    - Tests various sharing actions having share permissions

 * [Ensures correct etag propagation 1](lib/owncloud/test_sharePropagationGroups.py)
 * [Ensures correct etag propagation 2](lib/owncloud/test_sharePropagationInsideGroups.py)
    - Tests etag propagation sharing/resharing between groups of users


Important performance/integration tests
===============

[BASH script with all below tests](integration_test_cmds.sh)

**Note: Please refer to sections `Installation` and `First test runs` for more details. Mentioned below [index] refers to variable in the flag `-t [index]`**

 * [Upload/Download of small/big files](lib/test_nplusone.py)
    - Test should monitor upload/download sync time in each of the scenarious (TODO)
    - Test (index 0) verifies performance of many small files - 100 files - each 1kB
    - Test (index 2) verifies performance of few over-chunking-size files of total size 60MB
    - Test (index 3) verifies performance of 1 big over-chunking-size file of total size 60MB

 * [Upload/Download to/from shared folder](lib/oc-test/test_uploadFiles.py)
    - Test should monitor upload/download sync time (TODO)
    - Test (index 0) verifies performance of full upload/download sync for folder which has been shared with the user

 * TODO: Shared Mount Performance
    - Test should monitor number of server DB queries in each of the scenario
    - Test is initialized with users having incoming and outgoing shared files/directories of each type
    - PROPFIND on root folder - initialize mount points (initMount is done only on 1st propfind on received shares)
    - PROPFIND on root folder with initialized content and mount points
    - PUT to non-shared folder
    - PUT to shared folder
    - GET to non-shared folder
    - GET to shared folder

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

    # basic test, specifying test number as specified in tests' `testsets` array
    bin/smash -t 0 lib/test_basicSync.py

    # run a test with different paremeters
    bin/smash -o nplusone_nfiles=10 lib/test_nplusone.py
    
    # run all tests - print summaries only
    bin/smash --quiet lib/test_*.py

You will find main log files in ~/smashdir/log* and all temporary files and detailed logs for each test-case in ~/smashdir/<test-case>

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


