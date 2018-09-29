package main

import (
	"errors"

	"github.com/sjwhitworth/golearn/pca"
	"gonum.org/v1/gonum/mat"
)

type Dicts struct {
	DictList  []Dict
	WordCount map[string]int
}

type Dict struct {
	Words map[string]int
	Label string
}

type Bow struct {
	Vec    [][]float64
	Labels []string
}

func (d *Dicts) AddDictionary(dic Dict) {

	if d.WordCount == nil {
		d.WordCount = map[string]int{}
	}

	for word, count := range dic.Words {
		if _, ok := d.WordCount[word]; ok {
			d.WordCount[word] += count
		} else {
			d.WordCount[word] = count
		}
	}
	d.DictList = append(d.DictList, dic)
}

func (d *Dicts) Filter(label string) (filteredDicts []Dict) {
	for _, dic := range d.DictList {
		if dic.Label != label {
			filteredDicts = append(filteredDicts, dic)
		}
	}
	return
}

func (d *Dicts) Doc2Bow(dicts []Dict) (Bow, error) {
	words := []string{}
	bows := make([][]float64, len(dicts))
	labels := make([]string, len(dicts))

	for word := range d.WordCount {
		words = append(words, word)
	}

	if len(words) <= 0 {
		return Bow{}, errors.New("Empty train data.")
	}

	vec := make([]float64, len(dicts)*len(words))

	for i, dic := range dicts {
		bowVec := make([]float64, len(words))
		for j, word := range words {
			if count, ok := dic.Words[word]; ok {
				bowVec[j] = float64(count)
			} else {
				bowVec[j] = float64(0)
			}
			vec[i*j] = bowVec[j]
		}

		bows[i] = bowVec
		labels[i] = dic.Label
	}

	x := mat.NewDense(len(dicts), len(words), vec)
	pca := pca.NewPCA(4)
	dense := pca.FitTransform(x)

	for i := 0; i < len(dicts); i++ {
		bows[i] = dense.RawRowView(i)
	}

	return Bow{Vec: bows, Labels: labels}, nil
}
