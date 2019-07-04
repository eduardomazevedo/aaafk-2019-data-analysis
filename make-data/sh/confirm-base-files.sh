
# Don't want the script to exit if unlink returns an error, since this only happens when 
# trying to unlink a symlink that doens't exist.

set +o errexit

unlink raw-files/nkr
unlink raw-files/apd
unlink raw-files/unos-kpd
unlink raw-files/star
unlink raw-files/pra
unlink raw-files/zip
unlink intermediate-data
unlink datasets

# Now, we want to exit on error, that is, if these symlinks cannot successfully be made.

set -o errexit

ln -s /proj/orgad/raw-files/NKRRaw                     raw-files/nkr
ln -s /proj/orgad/raw-files/APDRaw                     raw-files/apd
ln -s /proj/orgad/raw-files/UNOSKPDRaw                 raw-files/unos-kpd
ln -s /proj/orgad/raw-files/PRAcalculation             raw-files/pra
ln -s /proj/orgad/raw-files/zip                        raw-files/zip
ln -s /local-data/orgad-$USER/raw-extract-3            raw-files/star
ln -s /local-data/orgad-$USER/$USER/intermediate-data  intermediate-data
ln -s /local-data/orgad-$USER/$USER/datasets           datasets

# Make sure all directories in intermediate are initialized.

for dir in all_ch apd nkr sim star unos; do
  if ! [ -d ./intermediate-data/$dir ]; then
    mkdir ./intermediate-data/$dir
  fi
done

if ! [ -d ./intermediate-data/nkr ]; then
  mkdir ./intermediate-data/nkr
fi
# Finally, tn theory, we should test the presence of all basic files that the scripts use.

test -e ./raw-files/nkr/additional-xplanted.csv
test -e ./raw-files/nkr/blockFileReal.csv
test -e ./raw-files/nkr/snapshots
