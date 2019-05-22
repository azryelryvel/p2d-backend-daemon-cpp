# Compiler
CXX=g++

# Paths to add to library path (-L)
LIBTORRENT_LIBRARY_PATH=/opt/libtorrent/bin/gcc-6.3.0/debug/link-static/threading-multi
GRPC_LIBRARY_PATH=/opt/grpc/libs/opt
PROTOBUF_LIBRARY_PATH=/opt/grpc/third_party/protobuf/src/.libs/

# Libraries options
LIBRARIES=-L$(LIBTORRENT_LIBRARY_PATH) -L$(GRPC_LIBRARY_PATH) -L${PROTOBUF_LIBRARY_PATH} -ltorrent -lpthread -lgrpc++ -lprotobuf -lgrpc -lcares -lz

# Includes options
INCLUDES=-Iincludes -I/opt/libtorrent/include -I/opt/boost -I/opt/grpc/include -I/opt/grpc/third_party/protobuf/src/

# Directory containing the sources
SRC_PATH = cpp

# Path to the builded code files
BUILD_PATH = build

# Path to the generated binaries
BIN_PATH = $(BUILD_PATH)/bin

# Name of the main binary
BIN_NAME = p2pd

# Files extension of the source files
SRC_EXT = cpp

# Source files to compile
SOURCES = $(shell find $(SRC_PATH) -name '*.$(SRC_EXT)' | sort -k 1nr | cut -f2-)

# Compiled files names
OBJECTS = $(SOURCES:$(SRC_PATH)/%.$(SRC_EXT)=$(BUILD_PATH)/%.o)

# Set the dependency files that will be used to add header dependencies
#DEPS = $(OBJECTS:.o=.d)

# Other flags
COMPILE_FLAGS = -std=c++11

###########################################################

.PHONY: default_target
default_target: release

.PHONY: release
release: export CXXFLAGS := $(CXXFLAGS) $(COMPILE_FLAGS)
release: dirs
	@$(MAKE) all

.PHONY: dirs
dirs:
	@echo "Creating directories"
	@mkdir -p $(dir $(OBJECTS))
	@mkdir -p $(BIN_PATH)

#    @echo "Generating protocol buffers"


.PHONY: clean
clean:
	@echo "Deleting $(BIN_NAME) symlink"
	@$(RM) $(BIN_NAME)
	@echo "Deleting directories"
	@$(RM) -r $(BUILD_PATH)
	@$(RM) -r $(BIN_PATH)

# checks the executable and symlinks to the output
.PHONY: all
all: $(BIN_PATH)/$(BIN_NAME)
	@echo "Making symlink: $(BIN_NAME) -> $<"
	@$(RM) $(BIN_NAME)
	@ln -s $(BIN_PATH)/$(BIN_NAME) $(BIN_NAME)

# Creation of the executable
$(BIN_PATH)/$(BIN_NAME): $(OBJECTS)
	@echo "Linking: $@"
	$(CXX) $(OBJECTS) -o $@ $(INCLUDES) $(LIBRARIES)

# Source file rules
# After the first compilation they will be joined with the rules from the
# dependency files to provide header dependencies
$(BUILD_PATH)/%.o: $(SRC_PATH)/%.$(SRC_EXT)
	@echo "Compiling: $< -> $@"
	$(CXX) $(LIBRARIES) $(INCLUDES) $(CXXFLAGS) -c $< -o $@
