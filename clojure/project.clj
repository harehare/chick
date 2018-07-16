(defproject chick "1.0.0-SNAPSHOT"
  :dependencies [[org.clojure/clojure "1.9.0"]
                 [org.clojure/clojurescript "1.10.339"]
                 [org.clojure/math.combinatorics "0.1.4"]
                 [io.replikativ/konserve "0.5.0-beta4"]]
  :plugins [[lein-cljsbuild "1.1.7"]]
  :cljsbuild {:builds {:dev {:source-paths ["src"]
                             :compiler {:main "chick.core"
                                        :output-to "compiled/main.js"
                                        :output-dir "compiled"
                                        :source-map "compiled/main.js.map"
                                        :externs ["chrome_extensions.js"]
                                        :optimizations :whitespace
                                        :pretty-print true}}}})
