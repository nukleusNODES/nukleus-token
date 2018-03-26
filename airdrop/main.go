package main

import (
	"encoding/csv"
	"io/ioutil"
	"log"
	"math/big"
	"os"
	_ "strconv"
	"strings"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

func main() {

	conf := GetConfig()

	contractAddress := common.HexToAddress(conf.ContractAddress)

	privateKey := getPrivateKeyContent(conf.PrivateKeyPath)
	privateKeyPassphrase := conf.PrivateKeyPassphrase
	node := conf.NodeAddress

	client, err := ethclient.Dial(node)

	if err != nil {
		log.Printf("Failed to connect ethereum client [%s], Error [%v]", node, err)
	}

	log.Printf("Connection established %v", client)

	auth, err := bind.NewTransactor(strings.NewReader(privateKey), privateKeyPassphrase)

	if err != nil {
		log.Fatalf("Invalid private key password! Failed to create authorized transactor: %v ", err)
	}

	log.Printf("Auth: %x", auth.From)

	contract, err := bindMain(contractAddress, client, client, nil)

	if err != nil {
		log.Fatalf("Failed to instantiate Nukleus contract: %v", err)
	}

	log.Println("Nukleus contract is instanticated!")

	tOpts := bind.TransactOpts{
		From:     auth.From,
		Signer:   auth.Signer,
		GasLimit: conf.MaxGasLimit,
		GasPrice: new(big.Int).SetUint64(conf.GasPrice),
	}

	tts := &MainTransactorSession{
		Contract: &MainTransactor{
			contract: contract,
		},
		TransactOpts: tOpts,
	}
	log.Println(tts)
	recipents := readCSV(conf.RecipientsCSVPath)

	r := csv.NewReader(strings.NewReader(recipents))

	records, err := r.ReadAll()

	if err != nil {
		log.Fatalf("Error occured while parsing the csv file: %v", err)
	}

	recordsLen := len(records)

	if recordsLen < 1 {
		log.Fatalf("CSV file is empty!")
	}

	var addresses []common.Address
	var values []*big.Int

	for i := 0; i < recordsLen; i++ {

		record := records[i]
		if len(record) < 2 {
			continue
		}

		address := common.HexToAddress(record[0])

		tokens, ok := new(big.Int).SetString(strings.TrimSpace(record[1]), 10)

		// log.Printf("%d Address %x will receive %d Tokens", i, address, tokens)
		if ok {
			addresses = append(addresses, address)
			values = append(values, tokens)

		} else {
			log.Printf("Error parsing input from csv [%s] for [%s]", record[1], record[0])
		}
	}

	log.Printf("%v -> %v", addresses, values)
	transaction, err := tts.Send(addresses, values)

	if err != nil {
		log.Println(err)
		return
	}

	log.Printf("Trnsaction accepted by network. Tx %x", transaction.Hash())

}

func readCSV(path string) string {

	if _, err := os.Stat(path); err != nil {
		log.Fatalf("CSV file [%s] is not readable or doesn't exists.", path)
	}

	log.Printf("Reading the csv file [%s]", path)

	bytes, err := ioutil.ReadFile(path)

	if err != nil {
		log.Fatalf("Error occured while reading the content of csv file %v", err)
	}

	return string(bytes)
}

func getPrivateKeyContent(path string) string {

	if _, err := os.Stat(path); err != nil {
		log.Fatalf("Private key [%s] is not readable or doesn't exists.", path)
	}

	log.Printf("Reading the private key [%s]", path)

	bytes, err := ioutil.ReadFile(path)

	if err != nil {
		log.Fatalf("Error occured while reading the content of private key %v", err)
	}

	return string(bytes)

}
