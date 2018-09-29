package main

import (
	"math"
	"sort"
)

var distances []KNNEntry

func calcDistance(x, dest []float64) float64 {
	val := 0.0
	for i, v := range x {
		val += math.Pow(v-dest[i], 2)
	}
	return math.Sqrt(val)
}

func uniq(strings []string) (results []string) {
	flg := map[string]bool{}
	for _, str := range strings {
		if !flg[str] {
			flg[str] = true
			results = append(results, str)
		}
	}
	return
}

type KNN struct {
	K         int
	TrainData [][]float64
	Labels    []string
}

type KNNEntry struct {
	label    string
	distance float64
}

func (n *KNN) Fit(x [][]float64, y []string) {
	n.TrainData = x
	n.Labels = y
}

func (n *KNN) KNeighbors(x int) (entries []KNNEntry) {
	neighbors := map[string]KNNEntry{}

	for _, d := range distances {
		if _, ok := neighbors[d.label]; !ok {
			neighbors[d.label] = d
		}
	}

	for _, v := range neighbors {
		entries = append(entries, v)
	}

	return
}

func (n *KNN) Predict(x []float64) (nearestLabels []string) {

	type kv struct {
		Key   string
		Value int
	}

	distances = make([]KNNEntry, len(n.TrainData))

	for i, dest := range n.TrainData {
		distances[i] = KNNEntry{label: n.Labels[i], distance: calcDistance(x, dest)}
	}
	sort.Slice(distances, func(i, j int) bool { return distances[i].distance < distances[j].distance })

	if len(distances) > n.K {
		distances = distances[:n.K]
	}

	freqLabel := map[string]int{}

	for _, d := range distances {
		if _, ok := freqLabel[d.label]; ok {
			freqLabel[d.label]++
		} else {
			freqLabel[d.label] = 1
		}
	}

	var sortedLabel []kv
	for k, v := range freqLabel {
		sortedLabel = append(sortedLabel, kv{k, v})
	}

	sort.Slice(sortedLabel, func(i, j int) bool {
		return sortedLabel[i].Value < sortedLabel[j].Value
	})

	for _, v := range sortedLabel {
		nearestLabels = append(nearestLabels, v.Key)
	}

	return
}
