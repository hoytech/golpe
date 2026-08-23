APPS     ?=
export APPS

W        ?= -Wall
OPT      ?= -O2 -g
STD      ?= -std=c++20

ifeq ($(OS),Windows_NT)
    BIN_EXE = $(BIN).exe
    WS_LIBS = -lws2_32 -luv -lbcrypt
    DL_LIBS =
else
    BIN_EXE = $(BIN)
    WS_LIBS =
    DL_LIBS = -ldl
endif

CXXFLAGS += $(STD) $(OPT) $(W) -fPIC $(XCXXFLAGS) -DDOCOPT_HEADER_ONLY
INCS     += -Iinclude -Ibuild -Isrc -Igolpe/external -Igolpe/external/lmdbxx/include -Igolpe/external/config/include -Igolpe/external/json/include -Igolpe/external/PEGTL/include -Igolpe/external/hoytech-cpp -Igolpe/external/docopt.cpp -Igolpe/external/loguru -Igolpe/external/parallel-hashmap -Igolpe/external/session-token-cpp/include
LDLIBS   += $(shell perl -Igolpe -Igolpe/vendor golpe/if-feature.pl websockets golpe/external/uWebSockets/libuWS.a) $(shell perl -Igolpe -Igolpe/vendor golpe/if-feature.pl db -llmdb) $(shell perl -Igolpe -Igolpe/vendor golpe/if-feature.pl ssl,websockets '-lcrypto -lssl') $(shell perl -Igolpe -Igolpe/vendor golpe/if-feature.pl zlib,websockets -lz) $(DL_LIBS) -pthread $(WS_LIBS)
LDFLAGS  += -flto $(XLDFLAGS)
SRCS    := golpe/logging.cpp build/main.cpp $(shell perl -Igolpe -Igolpe/vendor golpe/if-feature.pl config build/config.cpp) $(wildcard src/*.cpp) $(wildcard $(foreach p,$(APPS),src/apps/$(p)/*.cpp))

OBJS    := $(SRCS:.cpp=.o)
DEPS    := $(SRCS:.cpp=.d)

JUNK_ARG := $(shell perl -Igolpe -Igolpe/vendor golpe/pre-build.pl)

SETUP_CHECK_FILE := golpe/external/hoytech-cpp/README.md

.PHONY: all clean setup-golpe update-submodules gitmodules-dev-config

all: $(BIN_EXE)

$(BIN_EXE): $(SETUP_CHECK_FILE) $(OBJS) $(DEPS) $(shell perl -Igolpe -Igolpe/vendor golpe/if-feature.pl db build/defaultDb.h) $(shell perl -Igolpe -Igolpe/vendor golpe/if-feature.pl websockets golpe/external/uWebSockets/libuWS.a)
	$(CXX) $(OBJS) $(CMDOBJS) $(LDFLAGS) $(LDLIBS) -o $(BIN_EXE)

golpe/external/uWebSockets/libuWS.a:
	cd golpe/external/uWebSockets && $(MAKE) -j$(NPROC) libuWS.a

%.o : %.cpp build/golpe.h $(shell perl -Igolpe -Igolpe/vendor golpe/if-feature.pl config build/config.h) $(shell perl -Igolpe -Igolpe/vendor golpe/if-feature.pl db build/defaultDb.h)
	$(CXX) $(CXXFLAGS) $(INCS) -MMD -MP -MT $@ -MF $*.d -c $< -o $@

build/config.o: OPT=-O0 -g

build/main.cpp: golpe/main.cpp.tt golpe/gen-main.cpp.pl build/app_git_version.h
	perl -Igolpe -Igolpe/vendor golpe/gen-main.cpp.pl

build/config.cpp: golpe/config.cpp.tt golpe/gen-config.pl $(wildcard golpe.yaml src/apps/*/golpe.yaml)
	perl -Igolpe -Igolpe/vendor golpe/gen-config.pl

build/config.h: build/config.cpp $(wildcard golpe.yaml src/apps/*/golpe.yaml)

build/golpe.h: golpe/golpe.h.tt golpe/gen-golpe.h.pl $(wildcard global.h) $(wildcard *.fbs)
	perl -Igolpe -Igolpe/vendor golpe/gen-fbs.pl
	perl -Igolpe -Igolpe/vendor golpe/gen-golpe.h.pl

-include $(foreach p,$(APPS),src/apps/$(p)/rules.mk)

-include src/*.d src/apps/*/*.d

%.d : ;

build/defaultDb.h: $(wildcard golpe.yaml src/apps/*/golpe.yaml)
	perl -Igolpe/vendor golpe/external/rasgueadb/rasgueadb-generate golpe.yaml build

clean:
	rm -f $(BIN) $(BIN).exe src/*.{o,d} src/apps/*/*.{o,d}
	rm -rf build/
	$(foreach dir, config json lmdbxx PEGTL uWebSockets, $(MAKE) -C golpe/external/$(dir) clean;)

update-submodules:
	git submodule update --init
	cd golpe && git submodule update --init

setup-golpe:
	cd golpe/external && git submodule update --init hoytech-cpp session-token-cpp docopt.cpp loguru parallel-hashmap \
	    $(shell perl -Igolpe -Igolpe/vendor golpe/if-feature.pl config config) \
	    $(shell perl -Igolpe -Igolpe/vendor golpe/if-feature.pl config,json,pegtl 'json PEGTL' ) \
	    $(shell perl -Igolpe -Igolpe/vendor golpe/if-feature.pl db rasgueadb ) \
	    $(shell perl -Igolpe -Igolpe/vendor golpe/if-feature.pl db lmdbxx ) \
	    $(shell perl -Igolpe -Igolpe/vendor golpe/if-feature.pl templar templar ) \
	    $(shell perl -Igolpe -Igolpe/vendor golpe/if-feature.pl websockets uWebSockets )

$(SETUP_CHECK_FILE):
	$(error Please run 'make setup-golpe')

gitmodules-dev-config:
	perl -pi -e 's{https://github.com/([^/]+)/(\S+)}{git\@github.com:$$1/$$2}' .git/modules/external/*/config .git/modules/golpe/config .git/modules/golpe/modules/external/*/config
