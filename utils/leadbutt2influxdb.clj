;; A script to read output from cloudwatch-to-graphite's leadbutt
;; and convert it into a JSON suitable for InfluxDB
;; Usage:
;; lein exec leadbutt2json.clj leadbutt.output # => leadbutt.output.out.json
;; curl -X POST -ind @leadbutt.output.out.json "http://your.influxdb.api/db/data/series?time_precision=s"
;; (provided there is a DB called 'data' and you have your username+password in ~/.netrc)

(try (require '[leiningen.exec :as exec])
     (when @(ns-resolve 'leiningen.exec '*running?*)
       (leiningen.exec/deps '[[org.clojure/data.csv "0.1.2"]
                 [org.clojure/data.json "0.2.6"]]))
     (catch java.io.FileNotFoundException e))

(ns leadbutt-2-json.core
  (:require [clojure.data.csv :as csv]
            [clojure.data.json :as json]
            [clojure.java.io :as io]))


(defn read-csv [in-file-name]
  (print "Reading" in-file-name "...")
  (with-open [in-file (clojure.java.io/reader in-file-name)]
   (doall
    (csv/read-csv in-file :separator \ ))))

(defn mk-series [[name points]]
  {:name name
   :columns ["value" "time"]
   :points points})

(defn format-values [values] ;; [ [name value time] ... ]
  (->> values
       (map rest)
       (map (fn [[val time]] [(Double/parseDouble val) (Integer/parseInt time)]))))

(defn format-data [data]
  (->> data
       (group-by first)
       (reduce-kv (fn [acc k vs]
                    (assoc acc k
                           (format-values vs))) {})
       (seq)
       (map mk-series)))

(defn write-json [out-file data]
  (print "Writing" out-file "...")
  (with-open [out (io/writer out-file)]
    (comment binding [*out* out]
             (json/pprint data))
    (json/write data out)))

(defn -main [in-file]
  (->> (read-csv in-file)
       (format-data)
       (write-json (str in-file ".out.json"))))

;; lein-exec support
(try (require 'leiningen.exec)
     (when @(ns-resolve 'leiningen.exec '*running?*)
       (apply -main (rest *command-line-args*)))
     (catch java.io.FileNotFoundException e))
