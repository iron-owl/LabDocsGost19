#!/bin/bash

# Default values
DEBUG=false
NOLIB=false
XELATEX=false
RED='\033[0;31m'
NOCOLOR='\033[0m'
TEMPDATAPATH="build"
PROJECTNAME=""

# Function to handle interrupt signal
cleanup() {
    echo -e "\nCleaning up and exiting..."
    # Clean up temporary directory if debug mode is off
    if [ "$DEBUG" = false ]; then
        rm -rf ${TEMPDATAPATH}
    fi
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -d|--debug)
        DEBUG=true
        ;;
        -nl|--nolib)
        NOLIB=true
        ;;
        -x|--xelatex)
        XELATEX=true
        ;;
        *.tex)
        PROJECTNAME="${1%.tex}"
        ;;
        *)
        # Filename without extension
        PROJECTNAME="$1"
        ;;
    esac
    shift
done

# Check if filename provided
if [ -z "$PROJECTNAME" ]; then
    echo "Please provide a valid .tex file name."
    exit 1
fi

# Function to print messages with color
print_msg() {
    if [ "$DEBUG" = true ]; then
        echo -e "${RED}$1${NOCOLOR}"
    fi
}

# Trap interrupt signal
trap cleanup INT

# If build directory exists, remove it
if [ -d "$TEMPDATAPATH" ]; then
    echo "Removing existing $TEMPDATAPATH directory..."
    rm -rf "$TEMPDATAPATH"
fi

# Create temporary directory
mkdir ${TEMPDATAPATH}

# Determine LaTeX engine to use
if [ "$XELATEX" = true ]; then
    LATEXENGINE="xelatex"
else
    LATEXENGINE="pdflatex"
fi

# Compile LaTeX file
$LATEXENGINE -syntex=1 -shell-escape -interaction=nonstopmode -output-directory=${TEMPDATAPATH}/ $PROJECTNAME.tex 2>/dev/null 1>&2

# If requested, create Nomenclature List
if [ "$NOLIB" = false ] && [ -f ${TEMPDATAPATH}/$PROJECTNAME.nlo ]; then
    print_msg "******************** $PROJECTNAME.nlo exists --- Creating Nomenclature List ********************"
    makeindex ${TEMPDATAPATH}/$PROJECTNAME.nlo -s nomencl.ist -o ${TEMPDATAPATH}/$PROJECTNAME.nls 
fi

# If requested, create Bibliography
if [ "$NOLIB" = false ] && [ -f ${TEMPDATAPATH}/$PROJECTNAME.bcf ]; then
    print_msg "******************** $PROJECTNAME.bcf exists --- creating Bibliography ********************"
    biber ${TEMPDATAPATH}/$PROJECTNAME
fi

# Compile LaTeX file again for updates
$LATEXENGINE -syntex=1 -shell-escape -interaction=nonstopmode -output-directory=${TEMPDATAPATH}/ $PROJECTNAME.tex 2>/dev/null 1>&2
$LATEXENGINE -syntex=1 -shell-escape -interaction=nonstopmode -output-directory=${TEMPDATAPATH}/ $PROJECTNAME.tex 2>/dev/null 1>&2

# Check for errors in log file
grep error ${TEMPDATAPATH}/$PROJECTNAME.log

# Move compiled PDF to output directory
mv ${TEMPDATAPATH}/$PROJECTNAME.pdf output/

# Clean up temporary directory if debug mode is off
if [ "$DEBUG" = false ]; then
    rm -rf ${TEMPDATAPATH}
fi

exit 0