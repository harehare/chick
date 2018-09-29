package main

import (
	"log"
	"strings"
	"syscall/js"
)

var (
	knn  KNN
	dict Dicts
)

func main() {
	c := make(chan struct{}, 0)
	registerCallbacks()
	<-c
}

func addTrainData(i []js.Value) {
	detail := i[0].Get("detail")
	items := detail.Get("items")
	for i := 0; i < items.Length(); i++ {
		label := items.Index(i).Get("label").String()
		words := wordFreq(items.Index(i).Get("words"))
		dict.AddDictionary(Dict{Words: words, Label: label})
	}
	detail.Get("callback").Invoke()
}

func fit(i []js.Value) {
	detail := i[0].Get("detail")
	label := i[0].Get("label").String()
	bow, err := dict.Doc2Bow(dict.Filter(label))

	if err != nil {
		log.Panicln("Error fit")
		return
	}

	knn = KNN{K: detail.Get("k").Int()}
	knn.Fit(bow.Vec, bow.Labels)
	detail.Get("callback").Invoke()
}

func predict(i []js.Value) {
	detail := i[0].Get("detail")
	bow, err := dict.Doc2Bow([]Dict{Dict{Words: wordFreq(detail.Get("words")), Label: detail.Get("label").String()}})

	if err != nil {
		log.Panicln("Error predict")
		return
	}

	detail.Get("callback").Invoke(strings.Join(knn.Predict(bow.Vec[0]), ","))
}

func registerCallbacks() {
	js.Global().Get("document").Call("addEventListener", "addTrainData", js.NewCallback(addTrainData))
	js.Global().Get("document").Call("addEventListener", "fit", js.NewCallback(fit))
	js.Global().Get("document").Call("addEventListener", "predict", js.NewCallback(predict))
}

func wordFreq(obj js.Value) map[string]int {
	freq := map[string]int{}
	for i := 0; i < obj.Length(); i++ {
		word := obj.Index(i).String()
		if count, ok := freq[word]; ok {
			freq[word] += count
		} else {
			freq[word] = count
		}
	}

	return freq
}
