(defproject chick "1.0.0-SNAPSHOT"
  :dependencies [[org.clojure/clojure "1.9.0"]
                 [org.clojure/clojurescript "1.10.339"]
                 [cljs-ajax "0.7.3"]
                 [io.replikativ/konserve "0.5.0-beta4"]]
  :plugins [[lein-cljsbuild "1.1.7"]]
  :cljsbuild {:builds {:dev
                       {:source-paths ["src"]
                        :compiler {:main "chick.core"
                                   :output-to "compiled-dev/main.js"
                                   :output-dir "compiled-dev"
                                   :source-map "compiled-dev/main.js.map"
                                   :optimizations :whitespace
                                   :pretty-print true}}
                       :prod
                       {:source-paths ["src"]
                        :compiler {:main "chick.core"
                                   :output-to "compiled/main.js"
                                   :externs ["chrome_extensions.js"]
                                   :optimizations :advanced}}}})
