CLOJURE_JAR="$HOME/.m2/repository/org/clojure/clojure/1.2.0/clojure-1.2.0.jar"
# java -Xmx512m -Xms512m -XX:MaxNewSize=24m -XX:NewSize=24m -XX:+UseParNewGC -:+CMSParallelRemarkEnabled -XX:+UseConcMarkSweepGC -cp $CLOJURE_JAR clojure.main ca.clj
java -Xmx512m -Xms512m -XX:MaxNewSize=24m -XX:NewSize=24m -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -cp $CLOJURE_JAR clojure.main ca.clj

# java -Xmx512m -Xms512m -XX:MaxNewSize=24m -XX:NewSize=24m -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -cp $CLOJURE_JAR clojure.main transient-ca.clj
