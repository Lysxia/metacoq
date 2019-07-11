#!/usr/bin/env bash

# Removes all generated makefiles
make -f Makefile mrproper

# Dependencies for local or global builds.
# When building the packages separately, dependencies are not set as everything
# should already be available in $(COQMF_LIB)/user-contrib/MetaCoq/*
# checker is treated specially: due to code generation, we rebuild the template-coq module locally
# when building the checker package
# For local builds, we set specific dependencies of each subproject in */metacoq-config

if command -v coqc >/dev/null 2>&1
then
    COQLIB=`coqc -where`

    if [ "$1" == "local" ]
    then
        echo "Building MetaCoq locally"
        PCUIC_DEPS="-R ../template-coq/theories MetaCoq.Template"
        SAFECHECKER_DEPS="-I ../pcuic/src -R ../pcuic/theories MetaCoq.PCUIC"
        EXTRACTION_DEPS="-I ../safechecker/src -R ../safechecker/theories MetaCoq.SafeChecker"
    else
        echo "Building MetaCoq globally (default)"
        PCUIC_DEPS=""
        SAFECHECKER_DEPS=""
        EXTRACTION_DEPS=""

        # The pcuic plugin depends on the checker plugin
        # The extraction plugin relies on the checker and pcuic plugins.
        # These dependencies should not be necessary when separate linking of ocaml object
        # files is supported by coq_makefile
        PCUIC_DEPS=""
        SAFECHECKER_DEPS="-I $(COQLIB)/user-contrib/MetaCoq/SafeChecker"
        EXTRACTION_DEPS="-I $(COQLIB)/user-contrib/MetaCoq/PCUIC"
    fi

    echo ${PCUIC_DEPS} > pcuic/metacoq-config
    echo ${PCUIC_DEPS} ${SAFECHECKER_DEPS} > safechecker/metacoq-config
    echo ${PCUIC_DEPS} ${SAFECHECKER_DEPS} ${EXTRACTION_DEPS} > extraction/metacoq-config
else
    echo "Error: coqc not found in path"
fi
