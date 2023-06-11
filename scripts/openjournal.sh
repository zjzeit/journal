#!/bin/bash

# This script runs in Windows Subsystem for Linux (WSL) and assumes that 
# the alias "np" as defined in ~/.bash_aliases  points to notepad++.exe in Windows
set -euo pipefail
shopt -s expand_aliases
source ~/.bash_aliases

# Variables
JOURNALPATH=/mnt/c/path_to_journal/Journal/journal.tar.gz.gpg
GPGRECIPIENT="example@example.com"
CURRENTDATETIME=$(printf '%(%Y%m%d_%H%M%S)T\n' -1)
LATEXFILE=$(printf '%(%Y-%m-%d)T\n' -1).tex
LATEXFOLDER="journal/content/${LATEXFILE:0:4}"
JOURNALVARSFILE=~/.journalvars
OPENTIME=10800 # Time in seconds until journal gets auto-closed

# Ensure the journal is already closed before opening
if [ -s ${JOURNALVARSFILE} ]
then
	echo "Journal appears already open. Closing and then re-opening..."
	~/scripts/closejournal
fi

# Backup existing journal
cp -a ${JOURNALPATH} ${JOURNALPATH}_${CURRENTDATETIME}

# Make a temporary working directory.
TMPDIR=$(mktemp -d)
JOURNALTMPDIR="${TMPDIR}/journal"

# gpg decrypt journal.tar.gpg into tmpdir.
echo "Decrypting the journal into ${TMPDIR}. Please interact with the Yubikey."
gpg --quiet --decrypt ${JOURNALPATH} | tar -C ${TMPDIR} -xzf -

# Store variables into ${JOURNALVARSFILE} for reference when closing the journal.
echo JOURNALTMPDIR=${JOURNALTMPDIR} > ${JOURNALVARSFILE}
echo TMPDIR=${TMPDIR} >> ${JOURNALVARSFILE}
echo JOURNALPATH=${JOURNALPATH} >> ${JOURNALVARSFILE}
echo GPGRECIPIENT=${GPGRECIPIENT} >> ${JOURNALVARSFILE}

# As a failsafe, schedule closing of the journal.
echo "Note: the vault will auto-close in $((${OPENTIME} / 3600)) hour(s)."
nohup bash -c "sleep ${OPENTIME}; ~/scripts/closejournal" >/dev/null 2>&1 &

# Open notepad to type an entry to the journal.
mkdir -p ${TMPDIR}/${LATEXFOLDER}
touch ${TMPDIR}/${LATEXFOLDER}/${LATEXFILE}
sleep 1
np $(wslpath -w "${TMPDIR}/${LATEXFOLDER}/${LATEXFILE}") 
explorer.exe $(wslpath -w "${JOURNALTMPDIR}") 

