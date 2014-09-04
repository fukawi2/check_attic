check_attic
=============

Script to help monitor attic backup repositories (eg, with Nagios, Cacti etc)

USAGE
-----

    check_attic -p /path/to/attic/repo [-w warning_age] [-c critical_age]

'warning_age' and 'critical_age' are MINUTES. Default is 3600 (24 hours) and 10800 (3 days) respectively.

DEPENDENCIES
-----
Obviously, you need attic: https://attic-backup.org/
