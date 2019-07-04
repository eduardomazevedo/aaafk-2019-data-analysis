SHELL     := /bin/bash
stata     := ./sh/stata-batch.sh
r         := ./sh/r-batch.sh
user      := $(shell echo ${USER})
timestamp  = $(shell date +%s) 
start     := ${timestamp}
.PHONY: all clean remove_files stop_timer

# Inputs
tx_dta                  = ./datasets/transplant-level-data-full.dta
pair_dta                = ./datasets/pair-level-data-full.dta
ctr_dta                 = ./datasets/ctr-participation-dataset.dta
kidpan                  = ./raw-files/star/KIDPAN_DATA.DTA

# Dependencies

all: ./log/participation.log                \
     ./log/efficiency.log                   \
     ./log/summary.log                      \
     ./log/efficiency.R.log                 \
     ./log/tx-match-quality.log             \
     ./tables/pke-tx-summary.pdf            \
     ./tables/nkr-submissions-summary.pdf   \
     ./tables/tx-match-quality.pdf          \
     ./tables/tex-tables-compiled.pdf       \
     stop_timer

./log/participation.log:            $(tx_dta)  ./do/participation.do
	@echo "$(cyan)Running participation.do$(blue)"
	$(stata) ./do/participation.do

./log/efficiency.log:               $(pair_dta)  $(ctr_dta)  \
                                    ./do/efficiency.do       \
                                    ./intermediate-tables/pke-tx-summary.xls
	@echo "$(cyan)Running efficiency.do$(blue)"
	$(stata) ./do/efficiency.do;                      

./log/summary.log:                  $(pair_dta)  $(kidpan)  \
                                    ./do/summary.do         \
                                    ./intermediate-tables/nkr-submissions-summary.xls
	@echo "$(cyan)Running summary.do$(blue)"
	$(stata) ./do/summary.do

./log/efficiency.R.log:             $(tx_dta)    ./r/efficiency.R
	@echo "${cyan}Running efficiency.R${blue}"
	$(r) ./r/efficiency.R

./log/tx-match-quality.log:            $(tx_dta)    $(pair_data)                  \
                                    ./do/tx-match-quality.do                      \
                                    ./intermediate-tables/tx-match-quality.xls
	@echo "${cyan}Running tx-match-quality.do${blue}"
	$(stata) ./do/tx-match-quality.do

./tables/nkr-submissions-summary.pdf: ./intermediate-tables/nkr-submissions-summary.xls
	@echo "${cyan}Using libreoffice to convert nkr-submissions-summary.xls to pdf${blue}"
	libreoffice --headless --convert-to pdf --outdir ./tables ./intermediate-tables/nkr-submissions-summary.xls
	@echo "${cyan}Extracting first page of pdf with Ghostscript.${blue}"
	gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER        \
       -dFirstPage=1 -dLastPage=1                         \
       -sOutputFile=./tables/temp.pdf ./tables/nkr-submissions-summary.pdf
	mv --force ./tables/temp.pdf ./tables/nkr-submissions-summary.pdf

./tables/pke-tx-summary.pdf:          ./intermediate-tables/pke-tx-summary.xls
	@echo "${cyan}Using libreoffice to convert make pke-tx-summary.xls to pdf${blue}"
	libreoffice --headless --convert-to pdf --outdir ./tables ./intermediate-tables/pke-tx-summary.xls
	@echo "${cyan}Extracting first page of pdf with Ghostscript.${blue}"
	gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER        \
       -dFirstPage=1 -dLastPage=1                         \
       -sOutputFile=./tables/temp.pdf ./tables/pke-tx-summary.pdf
	mv --force ./tables/temp.pdf ./tables/pke-tx-summary.pdf

./tables/tx-match-quality.pdf:        ./intermediate-tables/tx-match-quality.xls \
                                      ./log/tx-match-quality.log
	@echo "${cyan}Using libreoffice to convert tx-match-quality.xls to pdf${blue}"
	libreoffice --headless --convert-to pdf --outdir ./tables ./intermediate-tables/tx-match-quality.xls
	@echo "${cyan}Extracting first page of pdf with Ghostscript.${blue}"
	gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER        \
       -dFirstPage=1 -dLastPage=1                         \
       -sOutputFile=./tables/temp.pdf ./tables/tx-match-quality.pdf
	mv --force ./tables/temp.pdf ./tables/tx-match-quality.pdf


./tables/tex-tables-compiled.pdf:     ./tables/tex-tables-compiled.tex  \
                                      ./log/selection-cross-section.log \
                                      ./log/efficiency.log
	@echo "${cyan}pdflatex for pdf${blue}"
	cd tables;                                                               \
	pdflatex -interaction=batchmode -halt-on-error tex-tables-compiled.tex;  \
	cd ..

clean: remove_files stop_timer

remove_files:
	@echo "$(yellow)Resetting environment."
	@echo "$(cyan)Refreshing link to the datasets and raw-files locations$(blue)"
	-unlink datasets
	ln -s /local-data/orgad-$(user)/$(user)/datasets datasets
	-unlink ./raw-files/star
	ln -s /local-data/orgad-$(user)/raw-extract-3 ./raw-files/star

	@echo "$(cyan)Purging figures, log, tables, intermediate-tables, and constants directories$(blue)"
	-rm ./figures/*
	-rm ./log/*
	-rm ./constants/*.txt

	@echo "$(cyan)Backing up and then restoring pke-tx-summary, nkr-submissions-summary, and tx-match-quality Excel files.$(blue)"
	mv ./intermediate-tables/pke-tx-summary.xls           .
	mv ./intermediate-tables/nkr-submissions-summary.xls  .
	mv ./intermediate-tables/tx-match-quality.xls         .
	mv ./intermediate-tables/pke-tx-summary-perfect.xls           .
	mv ./intermediate-tables/nkr-submissions-summary-perfect.xls  .
	mv ./intermediate-tables/tx-match-quality-perfect.xls         .
	-rm ./intermediate-tables/*
	mv ./pke-tx-summary.xls           ./intermediate-tables
	mv ./nkr-submissions-summary.xls  ./intermediate-tables
	mv ./tx-match-quality.xls         ./intermediate-tables
	mv ./pke-tx-summary-perfect.xls           ./intermediate-tables
	mv ./nkr-submissions-summary-perfect.xls  ./intermediate-tables
	mv ./tx-match-quality-perfect.xls         ./intermediate-tables
	

	@echo "$(cyan)Backing up and then restoring tex_tables_compiled.tex.$(blue)"
	mv ./tables/tex-tables-compiled.tex .
	set +o errexit
	-rm ./tables/*
	set -o errexit
	mv ./tex-tables-compiled.tex ./tables

stop_timer:
	@(( runtime=${timestamp}-${start} )); \
	 (( rhr =$$runtime/3600 ));           \
	 (( runtime=$$runtime%3600 ));        \
	 (( rmin=$$runtime/60 ));             \
	 (( rsec=$$runtime%60 ));             \
	 echo "$(cyan)Runtime was $${rhr}h:$${rmin}m:$${rsec}s."

# Colors

yellow = $(shell tput setaf 3)
blue   = $(shell tput setaf 4)
magenta= $(shell tput setaf 5)
cyan   = $(shell tput setaf 6)
