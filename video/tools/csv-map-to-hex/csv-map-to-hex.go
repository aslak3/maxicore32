package main

import (
	"encoding/csv"
	"fmt"
	"os"
	"strconv"
)

func output_csv_as_hex_tiles(filename string) {
	// Open the CSV file
	file, err := os.Open(filename)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	// Read the CSV data
	reader := csv.NewReader(file)
	reader.FieldsPerRecord = -1 // Allow variable number of fields
	data, err := reader.ReadAll()
	if err != nil {
		panic(err)
	}

	// Print the CSV data
	for _, row := range data {
		for _, col := range row {
			i, _ := strconv.Atoi(col)
			fmt.Printf("%02x\n", i)
		}
	}
}

func main() {
	args := os.Args[1:]

	if len(args) >= 1 {
		filename := args[0]

		output_csv_as_hex_tiles(filename)
	} else {
		fmt.Fprintf(os.Stderr, "filename not specified")
		os.Exit(1)
	}
}
