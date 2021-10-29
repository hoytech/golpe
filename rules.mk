W        ?= -Wall
OPT      ?= -O2 -g
STD      ?= -std=c++2a
CXXFLAGS += $(STD) $(OPT) $(W) -fPIC $(XCXXFLAGS) -DDOCOPT_HEADER_ONLY
INCS     += -Iinclude -Ibuild -Igolpe/external -Igolpe/external/config/include -Igolpe/external/json/include -Igolpe/external/PEGTL/include -Igolpe/external/hoytech-cpp -Igolpe/external/docopt.cpp -Igolpe/external/ethers-cpp
LDLIBS   += golpe/external/uWebSockets/libuWS.a -lz -lcrypto -lssl -llmdb -lgmp -lgmpxx -pthread
LDFLAGS  += -flto $(XLDFLAGS)
SRCS    := golpe/config.cpp build/main.cpp $(wildcard *.cpp)

OBJS    := $(SRCS:.cpp=.o)
DEPS    := $(SRCS:.cpp=.d)

.PHONY: all clean setup-golpe

all: $(BIN)

$(BIN): $(OBJS) $(DEPS) build/defaultDb.h golpe/external/uWebSockets/libuWS.a
	$(CXX) $(OBJS) $(CMDOBJS) $(LDFLAGS) $(LDLIBS) -o $(BIN)

golpe/external/uWebSockets/libuWS.a:
	cd golpe/external/uWebSockets && make -j libuWS.a

%.o : %.cpp %.d build/golpe.h build/defaultDb.h
	$(CXX) $(CXXFLAGS) $(INCS) -MMD -MP -MT $@ -MF $*.d -c $< -o $@

golpe/config.o: OPT=-O0 -g

build/main.cpp: golpe/main.cpp.tt golpe/gen-main.cpp.pl
	perl golpe/gen-main.cpp.pl

build/golpe.h: golpe/golpe.h.tt golpe/gen-golpe.h.pl $(wildcard global.h)
	perl golpe/gen-golpe.h.pl

-include *.d

%.d : ;

build/defaultDb.h: schema.yaml
	golpe/external/rasgueadb/rasgueadb-generate schema.yaml build

clean:
	rm -rf $(BIN) *.o *.d build/
	cd golpe/external/uWebSockets && make clean

setup-golpe:
	cd golpe && git submodule update --init
