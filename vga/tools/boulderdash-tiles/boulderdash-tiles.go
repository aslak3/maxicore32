package main

import (
	"fmt"
	"image/color"
	"os"
	"sort"

	"github.com/sergeymakinen/go-bmp"
)

func output_bmp_as_hex_tiles(filename string) {
	var palette = make(map[color.Color]int)
	f, _ := os.Open(filename)
	img, _ := bmp.Decode(f)

	bounds := img.Bounds()

	palette[color.RGBA{R: 0, G: 0, B: 0, A: 0}] = 0
	palette[color.RGBA{R: 15 * 16, G: 15 * 16, B: 15 * 16, A: 0}] = 1

	uniqueColors := 2

	for tile_y := 0; tile_y < bounds.Dy(); tile_y += 16 {
		for tile_x := 0; tile_x < bounds.Dx(); tile_x += 16 {
			for y := 0; y < 16; y++ {
				for x := 0; x < 16; x++ {
					pixel := img.At(tile_x+x, tile_y+y)
					r, g, b, _ := pixel.RGBA()
					newR := uint8((r / (256 * 16)) * 16)
					newG := uint8((g / (256 * 16)) * 16)
					newB := uint8((b / (256 * 16)) * 16)
					newPixel := color.RGBA{R: newR, G: newG, B: newB, A: 0}

					thisColor, ok := palette[newPixel]
					if !ok {
						fmt.Printf("%01x", uniqueColors)
						palette[newPixel] = uniqueColors
						uniqueColors++
					} else {
						fmt.Printf("%01x", thisColor)
					}
				}
				fmt.Printf("\n")
			}
			fmt.Printf("\n")
		}
	}

	keys := make([]color.Color, 0, len(palette))
	for key := range palette {
		keys = append(keys, key)
	}
	sort.Slice(keys, func(i, j int) bool { return palette[keys[i]] < palette[keys[j]] })

	for _, key := range keys {
		r, g, b, _ := key.RGBA()
		fmt.Printf("%1x%1x%1x%1x\n", 0, r/(256*16), g/(256*16), b/(256*16))
	}
}

func main() {
	args := os.Args[1:]

	if len(args) >= 1 {
		filename := args[0]

		output_bmp_as_hex_tiles(filename)
	} else {
		fmt.Fprintf(os.Stderr, "filename not specified")
		os.Exit(1)
	}
}
