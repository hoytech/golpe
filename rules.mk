ifeq ($(shell echo | gcc -E -dM - | grep -c __FreeBSD__),1)
    __FreeBSD__ = 1
endif

APPS     ?=
export APPS

W        ?= -Wall
OPT      ?= -O2 -g
STD      ?= -std=c++20

ifneq ($(origin __FreeBSD__), undefined)
CXX      = g++
CC       = cc
MAKE     = gmake
STD      += -stdlib=libc++
endif

CXXFLAGS += $(STD) $(OPT) $(W) -fPIC $(XCXXFLAGS) -DDOCOPT_HEADER_ONLY
INCS     += -Iinclude -Ibuild -Isrc -Igolpe/external -Igolpe/external/lmdbxx/include -Igolpe/external/config/include -Igolpe/external/json/include -Igolpe/external/PEGTL/include -Igolpe/external/hoytech-cpp -Igolpe/external/docopt.cpp -Igolpe/external/loguru -Igolpe/external/parallel-hashmap
LDLIBS   += golpe/external/uWebSockets/libuWS.a -ldl -lz -lcrypto -lssl -llmdb -pthread
LDFLAGS  += -flto $(XLDFLAGS)
SRCS    := golpe/logging.cpp build/main.cpp build/config.cpp $(wildcard src/*.cpp) $(wildcard $(foreach p,$(APPS),src/apps/$(p)/*.cpp))

ifneq ($(origin __FreeBSD__), undefined)
    INCS    += -I/usr/local/include  # Add FreeBSD-specific include paths
    LDLIBS  += -linotify -lc++ -luv
    NPROC = 2
endif


OBJS    := $(SRCS:.cpp=.o)
DEPS    := $(SRCS:.cpp=.d)

JUNK_ARG := $(shell perl golpe/pre-build.pl)

SETUP_CHECK_FILE := golpe/external/hoytech-cpp/README.md

.PHONY: all clean setup-golpe update-submodules gitmodules-dev-config

all: $(BIN)

$(BIN): $(SETUP_CHECK_FILE) $(OBJS) $(DEPS) build/defaultDb.h golpe/external/uWebSockets/libuWS.a
	$(CXX) $(OBJS) $(CMDOBJS) $(LDFLAGS) $(LDLIBS) -o $(BIN)

golpe/external/uWebSockets/libuWS.a:
	cd golpe/external/uWebSockets && make -j$(NPROC) libuWS.a

%.o : %.cpp build/golpe.h build/config.h build/defaultDb.h
	$(CXX) $(CXXFLAGS) $(INCS) -MMD -MP -MT $@ -MF $*.d -c $< -o $@

build/config.o: OPT=-O0 -g

build/main.cpp: golpe/main.cpp.tt golpe/gen-main.cpp.pl build/app_git_version.h
	perl golpe/gen-main.cpp.pl

build/config.cpp: golpe/config.cpp.tt golpe/gen-config.pl $(wildcard golpe.yaml src/apps/*/golpe.yaml)
	perl golpe/gen-config.pl

build/config.h: build/config.cpp $(wildcard golpe.yaml src/apps/*/golpe.yaml)

build/golpe.h: golpe/golpe.h.tt golpe/gen-golpe.h.pl $(wildcard global.h) $(wildcard *.fbs)
	perl golpe/gen-fbs.pl
	perl golpe/gen-golpe.h.pl

-include $(foreach p,$(APPS),src/apps/$(p)/rules.mk)

-include src/*.d src/apps/*/*.d

%.d : ;

build/defaultDb.h: $(wildcard golpe.yaml src/apps/*/golpe.yaml)
	golpe/external/rasgueadb/rasgueadb-generate golpe.yaml build

clean:
	rm -f $(BIN) src/*.o src/*.d src/apps/*/*.o src/apps/*/*.d
	rm -rf build/
	cd golpe/external/uWebSockets && make clean

update-submodules:
	git submodule update --init
	cd golpe && git submodule update --init

setup-golpe:
	cd golpe && git submodule update --init

$(SETUP_CHECK_FILE):
	$(error Please run 'make setup-golpe')

gitmodules-dev-config:
	perl -pi -e 's{https://github.com/([^/]+)/(\S+)}{git\@github.com:$$1/$$2}' .git/modules/external/*/config .git/modules/golpe/config .git/modules/golpe/modules/external/*/config
