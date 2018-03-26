package main

import (
	"flag"
	"io/ioutil"
	"log"
	"os"

	"gopkg.in/yaml.v2"
)

func init() {
	path := flag.String("config", "config.yaml", "-config=<config path>")
	flag.Parse()
	readAndMap(*path)
}

// Config struct for the app config
type Config struct {
	ContractAddress      string `yaml:"contract_address"`
	PrivateKeyPath       string `yaml:"private_key_path"`
	PrivateKeyPassphrase string `yaml:"private_key_passphrase"`
	NodeAddress          string `yaml:"node_address"`
	MaxGasLimit          uint64 `yaml:"max_gas_limit"`
	GasPrice             uint64 `yaml:"gas_price"`
	RecipientsCSVPath    string `yaml:"recipients_csv_path"`
}

var config *Config

// GetConfig function will return instance of Config
func GetConfig() *Config {
	return config
}

func readAndMap(path string) {
	if _, err := os.Stat(path); err != nil {
		log.Fatalf("config [%s] is not readable or doesn't exists!", path)
	}

	log.Printf("Reading config [%s].", path)

	bytes, err := ioutil.ReadFile(path)

	if err != nil {
		log.Fatalln(err)
	}

	if err := yaml.Unmarshal(bytes, &config); err != nil {
		log.Fatalln(err)
	}
}
