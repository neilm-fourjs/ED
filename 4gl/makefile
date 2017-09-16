
ifndef GENVER
export GENVER=310
endif
export FGLRESOURCEPATH=../etc
export FGLPROFILE=../etc/fglprofile
export FGLSQLDEBUG=0
export FGLCOVERAGE=0
export CLASSPATH=$(FGLDIR)/testing_utilities/ggc/ggc.jar:$(FGLDIR)/lib/fgl.jar
APPNAME=solve
GARNAME=Ruins$(GENVER)
GARFILE=packages/$(GARNAME).gar
WARFILE=packages/$(GARNAME).war
PROG=bin$(GENVER)/solve.42r
SRC=\
	src/solve.4gl \
	src/db_connect.4gl \
	src/calc_dist.4gl

all: $(PROG) gar

$(PROG): $(SRC)
	gsmake $(GARNAME).4pw

run: $(PROG)
	cd bin$(GENVER) && fglrun solve.42r

clean:
	rm -rf bin* packages logs test/*.guilog test/test_solve.4gl src/*.cov

# -------------
# GAR Files

packages: 
	mkdir packages	

gar: $(GARFILE)

$(GARFILE): packages bin$(GENVER)/solve.42r
	$(info Building Genero Archive ...)
	@cp gas$(GENVER)/solve.xcf .
	@zip -qr $(GARFILE) solve.xcf MANIFEST bin$(GENVER)/* etc/*.4?? db/*.db etc/fglprofile etc/njm_got.txt
	@rm -f solve.xcf

# ----------------------
# GAS Deploy 3.10

undeploy:
	gasadmin gar --disable-archive $(GARNAME)
	gasadmin gar --undeploy-archive $(GARNAME)

deploy: $(GARFILE)
	gasadmin gar --deploy-archive $(GARFILE)
	gasadmin gar --enable-archive $(GARNAME)


# -------------
# JGAS War

$(WARFILE): $(GARFILE)
	$(info Building Genero WAR File ...)
	fglgar war --input-gar $^ --output $@

runwar: $(WARFILE)
	fglgar run --war $^

launchurl: $(WARFILE)
	google-chrome	http://localhost:8080/$(GARNAME)/ua/r/$(APPNAME)

# -------------------
# Genero Ghost Client

test/solve.guilog: $(PROG)
	if [ ! -d test ]; then \
		mkdir test; \
	fi; \
	cd bin$(GENVER) && fglrun --start-guilog=../$@ solve.42r

test/test_solve.4gl: test/solve.guilog
	cd test; \
	rm -f test_solve.4gl; \
	java com.fourjs.ggc.generator.GhostGenerator solve.guilog com.fourjs.ggc.generator.BDLSimpleProducer test_solve.4gl

bin$(GENVER)/test_solve.42m: test/test_solve.4gl
	cd bin$(GENVER) && fglcomp ../test/test_solve.4gl

runtest: bin$(GENVER)/test_solve.42m
	cd bin$(GENVER) && fglrun test_solve.42m "fglrun solve.42r"

#	cd test && fglrun test_solve.42m http://localhost:6394/ua/r/solve

# -------------------
# Converage

runcov: $(PROG)
	cd bin$(GENVER) && FGLCOV=1 fglrun solve.42r; \
	mv *.cov ../src; \
	cd ../src; \
	fglrun --merge-cov solve.4gl; \
	cat solve.4gl.cov
