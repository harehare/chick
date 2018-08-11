local manifest = import 'manifest-base.jsonnet';

manifest {
  background: {
    scripts: ['clojure/compiled-dev/main.js', 'dist/background.js'],
    persistent: false,
  },
}
