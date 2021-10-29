#include <tao/config.hpp>

extern tao::config::value config;

void loadConfig(std::string configFile) {
    config = tao::config::from_file(configFile);
}
