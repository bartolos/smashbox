#!/bin/bash

#All basic sync tests
bin/smash -a lib/lib/test_basicSync.py

#All concurent dir remove tests
bin/smash -a lib/test_concurrentDirRemove.py

bin/smash lib/oc-test/test_reshareDir.py

bin/smash lib/oc-test/test_shareDir.py

bin/smash lib/oc-test/test_shareFile.py

bin/smash lib/oc-test/test_shareGroup.py

bin/smash lib/oc-test/test_shareLink.py

bin/smash lib/oc-test/test_sharePermissions.py

bin/smash lib/owncloud/test_sharePropagationGroups.py

bin/smash lib/owncloud/test_sharePropagationInsideGroups.py

#Some tests from Test_nplusone
bin/smash -t 0 lib/test_nplusone.py
bin/smash -t 2 lib/test_nplusone.py
bin/smash -t 3 lib/test_nplusone.py

#Some tests from test_upload
bin/smash -t 0 lib/oc-test/test_uploadFiles.py