#!/bin/bash

# This script runs in WSL
set -euo pipefail
shopt -s expand_aliases
JOURNALVARSFILE=~/.journalvars

# Ensure that ${JOURNALVARSFILE} is non-empty, because a separate call to close the journal empties the vars file.
if [ -s ${JOURNALVARSFILE} ]
then
	# Parse journal vars file
	source ${JOURNALVARSFILE}

	# Regenerate the index.tex
	echo "Closing the journal..."
	echo "Regenerating index.tex..."
	cd "${JOURNALTMPDIR}"
	echo '\newcommand*{\fileindex}{' > index.tex
	# Append a "," at the end of each line, except for the last. This is so LaTeX can parse the command correctly.
	find content -type f -iname "*.tex" | sort -rn | sed '$!s/$/,/' >> index.tex
	echo '}' >> index.tex

	# tar and encrypt journal directory
	echo "Encrypting and restoring journal.tar.gz.gpg"
	tar -C ${TMPDIR} -cz journal | gpg --quiet --encrypt --recipient ${GPGRECIPIENT} > ${JOURNALPATH}

	# Cleanup
	rm -rf ${TMPDIR}
	echo -n "" > ${JOURNALVARSFILE}

	# Remove any other background delay-close jobs. It's dirty but it works.
	# A better method is to track the PIDs of delay-close jobs in the JOURNALVARSFILE, but this satisfies for now.
	ps aux | grep "scripts/closejournal" | awk '{print $2}' | xargs kill 2>/dev/null
else
	echo "${JOURNALVARSFILE} appears empty. Journal appears closed."
fi

