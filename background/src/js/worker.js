import {
    sum,
    map,
    product,
    zip,
    sort,
    isEmpty
} from 'ramda';

class SimilarChecker {
    constructor(docs) {
        this.allWords = new Set();
        this.wordFreq = [];
        this.vector = [];
        this.labels = [];
        docs.forEach(doc => {
            if (isEmpty(doc.words)) {
                return;
            }
            this.labels.push(doc.label);
            const vec = {};
            doc.words.forEach(word => {
                vec[word] = vec[word] ? vec[word] + 1 : 1;
                this.allWords.add(word);
            })
            this.wordFreq.push(vec);
        });
    }

    fit() {
        this.vector = [];
        for (const v of this.wordFreq) {
            this.vector.push(this.doc2bow(v));
        }
    }

    freq(words) {
        const vec = {};
        words.forEach(word => {
            vec[word] = vec[word] ? vec[word] + 1 : 1;
        })
        return vec;
    }

    doc2bow(wf) {
        const bow = [];
        for (const word of this.allWords) {
            bow.push(wf[word] ? wf[word] : 0);
        }
        return bow;
    }

    predict(v, k) {
        const cos = this.vector.map(vec => {
            return Math.pow(sum(map(product, zip(v, vec))), 0.5) / (Math.pow(sum(map(x => x * x, v)), 0.5) * Math.pow(sum(map(x => x * x, vec)), 0.5));
        });
        return sort((a, b) => b.value - a.value, cos.map((value, index) => ({
            label: this.labels[index],
            value
        }))).slice(0, k);
    }
}

export {
    SimilarChecker
}