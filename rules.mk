APPS     ?=
export APPS

W        ?= -Wall
OPT      ?= -O2 -g
STD      ?= -std=c++20

CXXFLAGS += $(STD) $(OPT) $(W) -fPIC $(XCXXFLAGS) -DDOCOPT_HEADER_ONLY
INCS     += -Iinclude -Ibuild -Isrc -Igolpe/external -Igolpe/external/lmdbxx/include -Igolpe/external/config/include -Igolpe/external/json/include -Igolpe/external/PEGTL/include -Igolpe/external/hoytech-cpp -Igolpe/external/docopt.cpp -Igolpe/external/loguru -Igolpe/external/parallel-hashmap
LDLIBS   += $(shell golpe/if-feature.pl websockets golpe/external/uWebSockets/libuWS.a) $(shell golpe/if-feature.pl db -llmdb) $(shell golpe/if-feature.pl ssl,websockets '-lcrypto -lssl') $(shell golpe/if-feature.pl zlib,websockets -lz) -ldl -pthread
LDFLAGS  += -flto $(XLDFLAGS)
SRCS    := golpe/logging.cpp build/main.cpp $(shell golpe/if-feature.pl config build/config.cpp) $(wildcard src/*.cpp) $(wildcard $(foreach p,$(APPS),src/apps/$(p)/*.cpp))

OBJS    := $(SRCS:.cpp=.o)
DEPS    := $(SRCS:.cpp=.d)

JUNK_ARG := $(shell golpe/pre-build.pl)

SETUP_CHECK_FILE := golpe/external/hoytech-cpp/README.md

.PHONY: all clean setup-golpe update-submodules gitmodules-dev-config

all: $(BIN)

$(BIN): $(SETUP_CHECK_FILE) $(OBJS) $(DEPS) $(shell golpe/if-feature.pl db build/defaultDb.h) $(shell golpe/if-feature.pl websockets golpe/external/uWebSockets/libuWS.a)
	$(CXX) $(OBJS) $(CMDOBJS) $(LDFLAGS) $(LDLIBS) -o $(BIN)

golpe/external/uWebSockets/libuWS.a:
	cd golpe/external/uWebSockets && make -j$(NPROC) libuWS.a

%.o : %.cpp build/golpe.h $(shell golpe/if-feature.pl config build/config.h) $(shell golpe/if-feature.pl db build/defaultDb.h)
	$(CXX) $(CXXFLAGS) $(INCS) -MMD -MP -MT $@ -MF $*.d -c $< -o $@

build/config.o: OPT=-O0 -g

build/main.cpp: golpe/main.cpp.tt golpe/gen-main.cpp.pl build/app_git_version.h
	golpe/gen-main.cpp.pl

build/config.cpp: golpe/config.cpp.tt golpe/gen-config.pl $(wildcard golpe.yaml src/apps/*/golpe.yaml)
	golpe/gen-config.pl

build/config.h: build/config.cpp $(wildcard golpe.yaml src/apps/*/golpe.yaml)

build/golpe.h: golpe/golpe.h.tt golpe/gen-golpe.h.pl $(wildcard global.h) $(wildcard *.fbs)
	golpe/gen-fbs.pl
	golpe/gen-golpe.h.pl

-include $(foreach p,$(APPS),src/apps/$(p)/rules.mk)

-include src/*.d src/apps/*/*.d

%.d : ;

build/defaultDb.h: $(wildcard golpe.yaml src/apps/*/golpe.yaml)
	PERL5LIB=golpe/vendor/ golpe/external/rasgueadb/rasgueadb-generate golpe.yaml build

clean:
	rm -f $(BIN) src/*.o src/*.d src/apps/*/*.o src/apps/*/*.d
	rm -rf build/
	rm -f golpe/external/uWebSockets/src/{*.o,libuWS.a,libuWS.so}

update-submodules:
	git submodule update --init
	cd golpe && git submodule update --init

setup-golpe:
	cd golpe/external && git submodule update --init hoytech-cpp docopt.cpp loguru parallel-hashmap \
	    $(shell golpe/if-feature.pl config config) \
	    $(shell golpe/if-feature.pl config,json,pegtl 'json PEGTL' ) \
	    $(shell golpe/if-feature.pl db rasgueadb ) \
	    $(shell golpe/if-feature.pl templar templar ) \
	    $(shell golpe/if-feature.pl websockets uWebSockets )

$(SETUP_CHECK_FILE):
	$(error Please run 'make setup-golpe')

gitmodules-dev-config:
	perl -pi -e 's{https://github.com/([^/]+)/(\S+)}{git\@github.com:$$1/$$2}' .git/modules/external/*/config .git/modules/golpe/config .git/modules/golpe/modules/external/*/config
